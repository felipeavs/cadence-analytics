# Cadence Analytics

> Personal data pipeline that collects health metrics from Garmin Connect, combines them with manual exercise spreadsheets and multi-user synthetic data, processes at scale, and presents everything in an authenticated analysis interface.

## Project status

🚧 Work in progress — Phase 1 (Synthetic data generation)

## Overview

I train regularly and track my activity with a Garmin device, but the data ends up scattered: some metrics live in Garmin Connect, others in spreadsheets I fill in manually. There is no single place where I can look at sleep, resting heart rate, step count and training volume side by side and actually understand how they relate.

Cadence Analytics is my attempt to solve that. It ingests health data from Garmin Connect, merges it with manually tracked workouts, stores everything in a dimensional model, and exposes it through an API and an analysis dashboard.

A longer-term goal is to enrich the collected metrics with context from scientific literature, using retrieval-augmented generation (RAG) over research papers on sleep, recovery and training — so the data can answer not only *how am I doing*, but *what does this actually mean*.

The project also serves a second purpose: it is my hands-on portfolio for the transition from backend engineering into data engineering. Because a single user does not generate enough volume to justify distributed processing, the pipeline also includes a synthetic data generator that simulates hundreds of users — which makes the use of tools like Kafka and Spark meaningful rather than decorative.

## Architecture

_(Diagram coming soon — the pipeline currently covers the API and storage layers; streaming and distributed processing are in progress.)_

## Technologies

**Currently in use**

- Python 3.12
- FastAPI (REST API)
- PostgreSQL 16 (with pgvector extension)
- Docker / Docker Compose
- GitHub Actions (CI + automated releases)
- pytest
- NumPy, Faker (synthetic data generation)

**Planned**

- Apache Kafka (event ingestion)
- PySpark (distributed processing)
- Apache Airflow (orchestration)
- AWS (S3, EMR)
- Kubernetes (deployment study)
- React or Streamlit (dashboard)
- pgvector + LLM integration (RAG over scientific literature)

## Running locally

**Prerequisites:** Docker and Docker Compose installed.

```bash
# 1. Clone the repository
git clone https://github.com/felipeavs/cadence-analytics.git
cd cadence-analytics

# 2. Create your environment file
cp .env.example .env

# 3. Fill in the variables in .env (database credentials, at minimum)

# 4. Start the services
docker compose up --build
```

Once the containers are up:

- API health check: http://localhost:8000/health
- Interactive API docs (Swagger): http://localhost:8000/docs

To run the test suite locally:

```bash
pip install -r api/requirements.txt
pip install pytest
pytest tests/
```

To generate synthetic data:

```bash
pip install -r synthetic_data/requirements.txt
python -m synthetic_data.generator --usuarios 20 --dias 90
```

## Repository structure

```
cadence-analytics/
├── api/                  # FastAPI application (routers, models, repositories)
├── synthetic_data/       # Multi-user synthetic data generator
├── tests/                # Test suite
├── docs/adr/             # Architecture Decision Records
├── docker-compose.yml    # Local environment orchestration
└── requirements.txt      # Shared dependencies
```

## Technical decisions (ADRs)

See [`/docs/adr`](./docs/adr) for the history of architectural decisions.

## Versioning

This project uses [Semantic Versioning](https://semver.org/) with automated releases. Version numbers, tags, the changelog and GitHub Releases are generated automatically from [Conventional Commits](https://www.conventionalcommits.org/) whenever changes are merged into `main`.

See [CHANGELOG.md](./CHANGELOG.md) for the release history.

## Security

_(To be documented once authentication is implemented — planned: JWT-based authentication, password hashing with bcrypt, per-user data isolation, and secrets managed through environment variables.)_

## Roadmap

| Phase | Description | Status |
|---|---|---|
| 0 | Project setup, Docker, CI/CD, automated versioning | ✅ Done |
| 1 | Multi-user synthetic data generator | 🚧 In progress |
| 2 | Garmin Connect ingestion + Kafka | ⏳ Planned |
| 3 | S3 storage + dimensional modelling | ⏳ Planned |
| 4 | PySpark processing | ⏳ Planned |
| 5 | API + JWT authentication | ⏳ Planned |
| 6 | Test suite (pytest + BDD) | ⏳ Planned |
| 7 | Analysis dashboard | ⏳ Planned |
| 8 | Airflow orchestration | ⏳ Planned |
| 9 | Kubernetes deployment | ⏳ Planned |
| 10 | RAG over scientific literature (pgvector) | ⏳ Planned |

## License

MIT