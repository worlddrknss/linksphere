#!/usr/bin/env bash
set -euo pipefail

# setup_and_deploy.sh
# Checks Linux distro, installs Docker + docker-compose plugin if missing,
# builds and deploys the docker-compose stack from project root, and opens
# firewall ports (ufw or firewalld) as appropriate.
#
# Run with sudo for install operations:
#   sudo ./infra/scripts/setup_and_deploy.sh [--push] [--env-file PATH]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/../docker-compose.yml"

PUSH=false
ENV_FILE=""

usage(){
  cat <<EOF
Usage: $0 [--push] [--env-file PATH]

Options:
  --push         Build and push images to registry (compose must specify image names)
  --env-file     dotenv file to pass to docker compose
  -h, --help     Show this help
EOF
}

while [[ ${#} -gt 0 ]]; do
  case $1 in
    --push) PUSH=true; shift ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

echo "Project root: $ROOT_DIR"

detect_distro(){
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "$ID"
  else
    uname -s
  fi
}

install_docker_debian(){
  echo "Installing Docker on Debian/Ubuntu..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_rhel(){
  echo "Installing Docker on RHEL/CentOS/Fedora..."
  if command -v dnf >/dev/null 2>&1; then
    DPKG=dnf
  else
    DPKG=yum
  fi
  $DPKG install -y yum-utils
  mkdir -p /etc/yum.repos.d
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | gpg --dearmor -o /etc/pki/rpm-gpg/docker.gpg || true
  $DPKG config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
  $DPKG install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
  systemctl enable --now docker || true
}

ensure_docker(){
  if command -v docker >/dev/null 2>&1; then
    echo "Docker already installed"
  else
    DIST=$(detect_distro)
    echo "Detected distro: $DIST"
    if [[ "$DIST" =~ ubuntu|debian ]]; then
      install_docker_debian
    else
      install_docker_rhel
    fi
  fi

  # ensure docker daemon running
  if ! systemctl is-active --quiet docker; then
    echo "Starting docker service..."
    systemctl enable --now docker
  fi

  # check docker socket access
  if ! docker version >/dev/null 2>&1; then
    echo "Note: docker command failed. Are you running as root or in the docker group?" >&2
  fi
}

ensure_firewall(){
  # Open required ports: 80 (frontend), 8080 (backend), 5432 (postgres), 5050 (pgadmin)
  if command -v ufw >/dev/null 2>&1; then
    echo "Configuring ufw..."
    ufw allow 80/tcp || true
    ufw allow 8080/tcp || true
    ufw allow 5432/tcp || true
    ufw allow 5050/tcp || true
    ufw reload || true
  elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "Configuring firewalld..."
    firewall-cmd --permanent --add-port=80/tcp || true
    firewall-cmd --permanent --add-port=8080/tcp || true
    firewall-cmd --permanent --add-port=5432/tcp || true
    firewall-cmd --permanent --add-port=5050/tcp || true
    firewall-cmd --reload || true
  else
    echo "No supported firewall manager detected (ufw/firewalld). Please open ports 80,8080,5432,5050 if needed."
  fi
}

build_and_deploy(){
  DC_CMD=(docker compose -f "$COMPOSE_FILE")
  if [[ -n "$ENV_FILE" ]]; then
    DC_CMD+=(--env-file "$ENV_FILE")
  fi

  echo "Building images..."
  "${DC_CMD[@]}" build --pull --parallel

  if [[ "$PUSH" = true ]]; then
    echo "Pushing images to registry (if configured in compose)..."
    "${DC_CMD[@]}" push || echo "Push failed or not configured"
  fi

  echo "Bringing up postgres and waiting for health..."
  "${DC_CMD[@]}" up -d postgres

  # wait for postgres health
  for i in {1..30}; do
    status=$(docker inspect --format='{{json .State.Health.Status}}' linksphere-postgres 2>/dev/null || true)
    if [[ "$status" == '"healthy"' ]]; then
      echo "Postgres healthy"
      break
    fi
    echo "Waiting for postgres... ($i/30)"
    sleep 2
    if [[ $i -eq 30 ]]; then
      echo "Postgres did not become healthy in time" >&2
      docker logs linksphere-postgres --tail 200 || true
      exit 1
    fi
  done

  echo "Starting backend, frontend and pgadmin..."
  "${DC_CMD[@]}" up -d backend frontend pgadmin
  echo "All containers started"
  "${DC_CMD[@]}" ps
}

# Main flow
if [[ $EUID -ne 0 ]]; then
  echo "Note: this script performs installation and firewall changes. Run with sudo for full automation."
fi

ensure_docker
ensure_firewall
build_and_deploy

echo "Deployment finished. Check logs with e.g.:"
echo "  docker logs -f linksphere-backend"
