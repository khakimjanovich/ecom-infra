# ecom-infra

Local infrastructure for [ecom](https://github.com/khakimjanovich/ecom).

```bash
docker compose up -d
```

Brings up Postgres (one schema and one user per module, e.g. `partner_user` sees only `partner`; `ecom_viewer` reads every schema and writes nothing), Redis, Mailpit (a local SMTP server; read the emails at http://localhost:8025) and Keycloak (http://localhost:8180, realm `ecom`: roles `admin`, `partner` and `merchant` (a merchant's server), admins `aziz` and `malika`, the `ecom-backend` service client and the `ecom-portal` login client; login pages in English, Russian and Uzbek through the `ecom` theme). Passwords here are for local use only.
A processing sandbox (WireMock, http://localhost:8099) stands in for Uzcard and Humo, with test cards for every outcome: see `processing-sandbox/README.md`.
Vault (http://localhost:8200, token `local-only`, dev mode) keeps each API client's request-signing key under `secret/merchants/<client id>`. The bank puts keys there directly; the app only reads them:

```bash
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=local-only vault vault kv put secret/merchants/<client id> signingKey=$(openssl rand -base64 32)
```

Dev mode keeps everything in memory, so keys are gone after a restart.
SeaweedFS (http://localhost:8333, S3 API, access key `ecom` / `local-only`) stores files for the file service, the way any S3 would in production.
Temporal (dev server, gRPC on `7233`, UI at http://localhost:8233) keeps the workflows that resolve debits a card scheme didn't answer; its state lives in memory. Kafka is added when the system needs it.

## Observability

`observability` (Grafana's otel-lgtm image) takes OpenTelemetry over OTLP (`4317` gRPC, `4318` HTTP) and keeps metrics (Prometheus), traces (Tempo) and logs (Loki), with Grafana at http://localhost:3030 and the **ecom · payments** dashboard: debits by outcome, unknown and failed debits, the scheme's answer time, request time and server errors per service, database pool waits, and warnings with links to their traces. Data lives in memory and is gone after a restart.

The services are instrumented by the OpenTelemetry Java agent, not by code: `otel-agent` copies the pinned agent to `observability/agent/`, and `observability/agent.env` holds the settings. To run a service with it:

```bash
set -a; . ../ecom-infra/observability/agent.env; set +a
OTEL_SERVICE_NAME=ecom ./gradlew :app:bootRun   # or uzcard-adapter, humo-adapter, file-service
```

The agent traces HTTP in and out, JDBC and Redis (one trace follows a payment from the app into the adapters), exports JVM, HTTP and database pool metrics plus the app's own Micrometer meters, and sends logs with their trace ids. Locally every trace is kept; production samples (`OTEL_TRACES_SAMPLER`). The load stack runs without the agent, so k6 measures the code alone.

## The system under load

`load/docker-compose.yml` runs the app, the two adapters and the file service from their built jars, each limited like the target server: **1 CPU and 2 GB RAM** (the target also has a 256 GB SSD; Docker can't limit disk per container). The limits and JVM options live here, so load tests measure the code as it is. Start the main stack first, then `docker compose -f load/docker-compose.yml up -d`; the app answers on http://localhost:8085, which is where [ecom-k6-testing](https://github.com/khakimjanovich/ecom-k6-testing) points.

## Kubernetes

`k8s/base` runs the system on Kubernetes (Kustomize): the app with three replicas, a rolling update that starts a new pod before stopping an old one, Spring Boot's liveness and readiness probes, a `preStop` pause so the Service stops sending traffic before the graceful shutdown, a PodDisruptionBudget and a CPU autoscaler (3–6); the adapters and the file service with two replicas each. Addresses live in a ConfigMap; secrets come from the `ecom-secrets` Secret, created in the cluster from Vault and never kept in git. Postgres, Redis, Keycloak, Vault, Kafka, Temporal and the stores are outside the cluster. One image per deployable: `k8s/Dockerfile`, the jar on the plain JRE as a non-root user.

`k8s/local` tries it on a laptop with a one-node k3s in Docker, on the main stack's network:

```bash
docker compose -f k8s/local/docker-compose.yml up -d
docker build -f k8s/Dockerfile -t ecom/app:dev --build-arg JAR=app.jar ../ecom/app/build/libs   # and each service
docker save ecom/app:dev ecom/uzcard-adapter:dev ecom/humo-adapter:dev ecom/file-service:dev | docker exec -i ecom-k8s-k3s-1 ctr images import -
kubectl kustomize k8s/local | docker exec -i ecom-k8s-k3s-1 kubectl apply -f -
k8s/local/dependencies.sh | docker exec -i ecom-k8s-k3s-1 kubectl apply -f -
```

The app answers on http://localhost:30085 (two replicas, one of each service, local-only secrets). `dependencies.sh` gives the cluster Services named `postgres`, `kafka` and so on that point at the compose containers; run it again after the main stack restarts.
