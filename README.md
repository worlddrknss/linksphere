# LinkSphere

[![CI - Backend](https://github.com/WorldDrknss/LinkSphere/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/WorldDrknss/LinkSphere/actions/workflows/backend-ci.yml)

LinkSphere is a modern **URL shortener platform** built with **Go (backend)** and **React (frontend)**. It delivers fast link generation, robust click tracking, and an intuitive dashboard for managing and analyzing shortened URLs. Designed for scalability, security, and clear operations, LinkSphere fits both startup and enterprise environments.

---

## ✨ Features

* **Fast URL Shortening** — Low‑latency link creation with Go.
* **Analytics Dashboard** — Track clicks, referrers, geo, device/browser.
* **PostgreSQL Persistence** — Durable storage for links & events.
* **Cloud‑Native** — Containerized, IaC templates, and CI/CD workflows.

---

## 🧱 Architecture Overview

* **Backend**: Go.
* **Frontend**: React.

---

## 📂 Repository Layout

```text
LinkSphere/
├─ backend/              # Go service (chi, handlers, storage, migrations)
│  ├─ cmd/               # main package(s)
│  ├─ internal/          # domain, http, storage, auth, rate limit, etc.
│  ├─ migrations/        # SQL migrations
│  └─ go.mod
├─ frontend/             # React app (dashboard, auth, analytics views)
├─ infra/                # Terraform, ECS/EKS modules, pipeline configs
├─ .github/workflows/    # GitHub Actions (CI/CD)
└─ README.md
```

---

## 🚀 Quickstart (Local)

### Prerequisites

* Docker & Docker Compose
* Go 1.22+
* Node.js 20+
* PostgreSQL 14+ (optional if using Compose)

### Clone

```bash
git clone https://github.com/WorldDrknss/LinkSphere.git
cd LinkSphere
```

### Option A — Docker Compose (recommended)

```bash
docker compose up --build
```

This launches:

* **db**: PostgreSQL on `localhost:5432`
* **backend**: Go API on `http://localhost:8080`
* **frontend**: React dev server on `http://localhost:5173` (if configured)

### Option B — Run services manually

#### Backend

```bash
cd backend
cp .env.example .env
go mod tidy
go run ./cmd/linksphere
```

#### Frontend

```bash
cd frontend
cp .env.example .env
npm install
npm start
```

---

## ⚙️ Configuration

Create `.env` files from the examples in each package.

### Backend (.env)

```env
APP_NAME=linksphere
APP_ENV=local
PORT=8080
DB_HOST=localhost
DB_USER=myuser
DB_PASS=mypassword
DB_NAME=mydatabase
```

### Frontend (.env)

```env
REACT_APP_API_URL=http://localhost:8080/api/v1
```

---

## 🧪 Testing

### Backend Tests

```bash
cd backend
go test ./...
```

### Frontend Tests

```bash
cd frontend
npm test
```

(Optional) **E2E**: add Playwright/Cypress under `frontend/e2e`.

CI is defined in **.github/workflows** (e.g., `backend-ci.yml`).

---

## 🗺️ Roadmap

* [ ] URL expiration & one‑time links
* [ ] RBAC
* [ ] OpenTelemetry
* [ ] Advanced analytics

---

## 🤝 Contributing

Pull requests welcome! Please:

1. Open an issue describing the change.
2. Follow Conventional Commits.
3. Add tests and update docs.
4. Ensure CI passes.

---

## 📄 License

This project is licensed under the **MIT License**. See `LICENSE` for details.

---

## 📬 Contact

* Maintainer: Charles Showalter
* Issues: Use GitHub Issues for bugs and feature requests.
