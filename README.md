# ecom-infra

Local infrastructure for [ecom](https://github.com/khakimjanovich/ecom).

```bash
docker compose up -d
```

Brings up Postgres (one schema and one user per module, e.g. `partner_user` sees only `partner`; `ecom_viewer` reads every schema and writes nothing), Redis, Mailpit (a local SMTP server; read the emails at http://localhost:8025) and Keycloak (http://localhost:8180, realm `ecom`: roles `admin`, `partner` and `merchant` (a merchant's server), admins `aziz` and `malika`, the `ecom-backend` service client and the `ecom-portal` login client; every token, an API client's included, names the `ecom-api` audience (the default role grants `ecom-api`'s `caller` role, which Keycloak's audience resolve puts in `aud`), and the app accepts no other: every client of realm `ecom` is an API caller by design, which holds only while each keeps `fullScopeAllowed` on (Keycloak's default; a client that turns it off loses the audience); login pages in English, Russian and Uzbek through the `ecom` theme). Passwords here are for local use only.
A processing sandbox (WireMock, http://localhost:8099) stands in for Uzcard and Humo, with test cards for every outcome: see `processing-sandbox/README.md`.
Vault (http://localhost:8200, token `local-only`, dev mode) keeps each API client's request-signing key under `secret/merchants/<client id>`. The bank puts keys there directly; the app only reads them:

```bash
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=local-only vault vault kv put secret/merchants/<client id> signingKey=$(openssl rand -base64 32)
```

Dev mode keeps everything in memory, so keys are gone after a restart. Every other secret the app needs (card keys, the one-time-code secret, the Keycloak client secret, the S3 secret key, each module's database password) is put at `secret/ecom` by the one-shot `vault-seed` service (`vault/seed.sh`, public local-only values) on every `docker compose up`; the app imports that path (`spring.config.import: vault://secret/ecom`). After restarting Vault alone, run `docker compose up vault-seed` again. The app requires that path and has no default token: run it with `VAULT_TOKEN=local-only` (`VAULT_TOKEN=local-only ./gradlew :app:bootRun`); without any Vault, also `VAULT_IMPORT=optional:vault://secret/ecom VAULT_FAIL_FAST=false`. If Vault never answers, `vault-seed` gives up after 60 s and says so.
SeaweedFS (http://localhost:8333, S3 API, access key `ecom` / `local-only`) stores the app's files (merchants' documents, website logos), the way any S3 would in production. The buckets `partner-documents` and `sales-point-logos` are created by the one-shot `file-store-init` service (`seaweedfs/init.sh`); the app's identity may only read and write those two (`seaweedfs/s3.json`; nothing lists them), and the app only checks at startup that they exist.
Temporal (dev server, gRPC on `7233`, UI at http://localhost:8233) keeps the workflows that resolve debits a card scheme didn't answer; its state lives in memory. Kafka (KRaft, one node; `kafka:9092` inside Docker, `localhost:9102` from the host) carries payment events on `payments.events`, with failed deliveries on `payments.events.DLT`.

## Local accounts

Every login the local stack creates. All passwords are `local-only` and public; never use them outside a laptop.

| Account | Where | Login | Created by |
|---|---|---|---|
| Admin `aziz` (role `admin`) | the portal (http://localhost:5180/admin) and the API, realm `ecom` | `aziz` / `local-only` | `keycloak/ecom-realm.json`, imported when the Keycloak container starts (`start-dev --import-realm`) |
| Admin `malika` (role `admin`) | the same | `malika` / `local-only` | the same; two admins exist so an activation can be approved by a second admin (four-eyes) |
| Keycloak console | http://localhost:8180/admin, realm `master` | `admin` / `local-only` (`KEYCLOAK_ADMIN_PASSWORD`) | `KC_BOOTSTRAP_ADMIN_*` in `docker-compose.yml` |
| Service client `ecom-backend` | used by the app to call Keycloak's admin API | client secret in Vault (`secret/ecom`) | `keycloak/ecom-realm.json`, `vault/seed.sh` |
| Postgres owner | `localhost:5442`, database `acquiring` | `acquiring_admin` / `local-only` (`POSTGRES_PASSWORD`) | `docker-compose.yml` |
| One user per module | the same database, its own schema only | `partner_user`, `commission_user`, `epos_user`, `bin_user`, `card_user`, `payment_user` / `local-only` | `postgres/init.sql` |
| Read-only viewer (TablePlus) | every schema, no writes | `ecom_viewer` / `local-only` | `postgres/init.sql` |
| Vault | http://localhost:8200 | token `local-only` | dev mode root token; `vault-seed` writes the app's secrets to `secret/ecom` |
| File store (S3) | http://localhost:8333 | access key `ecom` / `local-only` | `seaweedfs/s3.json` |
| Grafana | http://localhost:3030 | `admin` / `admin` | the `grafana/otel-lgtm` image's default |
| Mailpit, Temporal UI, processing sandbox | http://localhost:8025, http://localhost:8233, http://localhost:8099 | no login | |

Keycloak keeps its data inside its container. Recreating the container (`docker compose down`, or `up` after an image change) imports the realm again: `aziz` and `malika` come back with `local-only`, and every partner, merchant and API client created since is gone. Restarting the same container keeps them. To change an admin's password for good, change it in `keycloak/ecom-realm.json`.

## Where to look

Each step of a process leaves its trace in one place:

| Process | Where | What you see |
|---|---|---|
| Sign-up and email codes | Mailpit, http://localhost:8025 | Every email the app sends: one-time codes, notices |
| Logins, roles, API clients | Keycloak, http://localhost:8180, realm `ecom` | Users, roles, machine clients, sessions |
| Documents and logos | SeaweedFS, S3 API on `localhost:8333` (`ecom` / `local-only`) | Buckets `partner-documents` and `sales-point-logos` |
| Merchants' signing keys | Vault, http://localhost:8200, token `local-only` | `secret/merchants/<client id>` |
| Every module's data | Postgres, `localhost:5442`, database `acquiring`, user `ecom_viewer` (read only) | Each module's schema: `partner`, `commission`, `epos`, `bin`, `card`, `payment` |
| One-time codes, nonces, page locks | Redis, `localhost:6389` | Short-lived keys such as `ecom:hmac:nonce:*` and `ecom:payment:page-lock:*` |
| Calls to Uzcard and Humo | Processing sandbox, http://localhost:8099/__admin/requests | Every call the adapters made, and the answer |
| A debit the scheme didn't answer | Temporal UI, http://localhost:8233 | One workflow per payment: each status check, wait and retry |
| Payment events and webhooks | Kafka, `localhost:9102` (no UI); table `payment.webhook_delivery` | Events on `payments.events`, failed ones on `payments.events.DLT`; every delivery attempt |
| One request end to end | Grafana, http://localhost:3030 → Tempo | The trace from the app into the adapters, with SQL and Redis |
| Errors and warnings | Grafana → Loki | Logs from every service, linked to their traces |
| Load, latency, debit outcomes | Grafana → **ecom · payments** (Prometheus) | Debits by scheme and outcome, p95 request time, database pool |
| What each module exposes | The app's Swagger UI, http://localhost:8080/swagger-ui/index.html | Public APIs, and the `…Internal` operations other modules call |

Reading the events:

```bash
docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic payments.events --from-beginning
```

One payment, in order: it is created (Swagger or k6), its status is in `payment.payment`, the scheme call is in the sandbox, a debit with no answer waits in Temporal, its event goes through Kafka with each webhook attempt in `payment.webhook_delivery`, and Grafana shows the whole path as one trace. Every request has one trace id: each log line carries it as `trace.id` (and `span.id`), the app returns it to callers as `X-Request-Id`, and it travels to the adapters (`traceparent`), through the outbox and Kafka, and into Temporal. To follow one request, filter the logs of every service by its `trace.id`, or open the trace in Grafana → Tempo.

## Observability

`observability` (Grafana's otel-lgtm image) takes OpenTelemetry over OTLP (`4317` gRPC, `4318` HTTP) and keeps metrics (Prometheus), traces (Tempo) and logs (Loki), with Grafana at http://localhost:3030 and the **ecom · payments** dashboard: debits by outcome, unknown and failed debits, the scheme's answer time, request time and server errors per service, database pool waits, and warnings with links to their traces. Data lives in memory and is gone after a restart.

The app and the adapters send their own telemetry over OTLP (Spring Boot with Micrometer and OpenTelemetry): traces to `OTLP_TRACES_ENDPOINT`, metrics to `OTLP_METRICS_ENDPOINT` and logs to `OTLP_LOGS_ENDPOINT` (default `localhost:4318`; the load stack and Kubernetes use `observability:4318`). Traces follow a request through HTTP in and out, the outbox, Kafka and Temporal; metrics are the JVM, HTTP, database pool and the app's own meters; every log line reaches Loki with its trace id, so a trace in Tempo links to its logs. Locally every trace is kept; production samples (`TRACING_SAMPLING`).

## The system under load

`load/docker-compose.yml` runs the app and the two adapters from their built jars, each limited like the target server: **1 CPU and 2 GB RAM** (the target also has a 256 GB SSD; Docker can't limit disk per container). The limits and JVM options live here, so load tests measure the code as it is. Start the main stack first, then `docker compose -f load/docker-compose.yml up -d`; the app answers on http://localhost:8085, which is where [ecom-k6-testing](https://github.com/khakimjanovich/ecom-k6-testing) points.

## Kubernetes

`k8s/base` runs the system on Kubernetes (Kustomize): the app with three replicas, a rolling update that starts a new pod before stopping an old one, Spring Boot's liveness and readiness probes, a `preStop` pause so the Service stops sending traffic before the graceful shutdown, a PodDisruptionBudget and a CPU autoscaler (3–6); the adapters with two replicas each. Addresses live in a ConfigMap; secrets come from the `ecom-secrets` Secret, created in the cluster from Vault and never kept in git. Postgres, Redis, Keycloak, Vault, Kafka, Temporal and the stores are outside the cluster. One image per deployable: `k8s/Dockerfile`, the jar on the plain JRE as a non-root user.

`k8s/local` tries it on a laptop with a one-node k3s in Docker, on the main stack's network:

```bash
docker compose -f k8s/local/docker-compose.yml up -d
docker build -f k8s/Dockerfile -t ecom/app:dev --build-arg JAR=app.jar ../ecom/app/build/libs   # and each service
docker save ecom/app:dev ecom/uzcard-adapter:dev ecom/humo-adapter:dev | docker exec -i ecom-k8s-k3s-1 ctr images import -
kubectl kustomize k8s/local | docker exec -i ecom-k8s-k3s-1 kubectl apply -f -
k8s/local/dependencies.sh | docker exec -i ecom-k8s-k3s-1 kubectl apply -f -
```

The app answers on http://localhost:30085 (two replicas, one of each service, local-only secrets). `dependencies.sh` gives the cluster Services named `postgres`, `kafka` and so on that point at the compose containers; run it again after the main stack restarts.
