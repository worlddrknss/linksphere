# LinkSphere

[![CI - Backend](https://github.com/WorldDrknss/LinkSphere/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/WorldDrknss/LinkSphere/actions/workflows/backend-ci.yml)
[![CI - Frontend](https://github.com/WorldDrknss/LinkSphere/actions/workflows/frontend-ci.yml/badge.svg)](https://github.com/WorldDrknss/LinkSphere/actions/workflows/frontend-ci.yml)

LinkSphere is a modern **URL shortener platform** built with **Go (backend)** and **React (frontend)**. It delivers fast link generation, robust click tracking, and an intuitive dashboard for managing and analyzing shortened URLs. Designed for scalability, security, and clear operations, LinkSphere fits both startup and enterprise environments.

---

## ✨ Features

* **Fast URL Shortening** — Low‑latency link creation with Go.
* **Analytics Dashboard** — Track clicks, referrers, geo, device/browser.
* **PostgreSQL Persistence** — Durable storage for links & events.
* **Cloud‑Native** — Containerized, IaC templates, and CI/CD workflows.

---

## 🧱 Architecture Overview

* **Backend**: Go with Chi router, PostgreSQL storage
* **Frontend**: React with TypeScript and Vite
* **Infrastructure**: Docker containers with multi-stage builds
* **CI/CD**: GitHub Actions with Docker image publishing

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
docker-compose up --build
```

This launches:

* **PostgreSQL**: Database on `localhost:5432`
* **pgAdmin**: Database admin interface on `http://localhost:5050`
* **Backend**: Go API on `http://localhost:8080`
* **Frontend**: React app on `http://localhost:3000`

#### pgAdmin Access

* **URL**: <http://localhost:5050>
* **Email**: `admin@linksphere.com`
* **Password**: admin123

#### Database Connection (for pgAdmin)

* **Host**: postgres
* **Port**: 5432
* **Database**: linksphere
* **Username**: linksphere_user
* **Password**: linksphere_password

### Option B — Run services manually

#### Backend

```bash
cd backend
cp .env.example .env  # Edit .env with your database settings
go mod tidy
go run ./cmd/server
```

#### Frontend

```bash
cd frontend
cp .env.example .env
npm install
npm run dev
```

---

## ⚙️ Configuration

Create `.env` files from the examples in each package.

### Backend (.env)

```env
PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_NAME=linksphere
DB_USER=linksphere_user
DB_PASS=linksphere_password
```

### Frontend (.env)

```env
VITE_API_URL=http://localhost:8080/api/v1
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

CI/CD is defined in **.github/workflows** with separate pipelines for backend (`backend-ci.yml`) and frontend (`frontend-ci.yml`), both using Docker builds and publishing to GitHub Container Registry.

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
