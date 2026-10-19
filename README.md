# ecom-infra

Local infrastructure for [ecom](https://github.com/khakimjanovich/ecom).

```bash
docker compose up -d
```

Brings up Postgres (one schema and one user per module, e.g. `partner_user` sees only `partner`), Redis, Mailpit (a local SMTP server; read the emails at http://localhost:8025) and Keycloak (http://localhost:8180, realm `ecom`: roles `admin`, `partner` and `merchant` (a merchant's server), admins `aziz` and `malika`, the `ecom-backend` service client and the `ecom-portal` login client; login pages in English, Russian and Uzbek through the `ecom` theme). Passwords here are for local use only.
A processing sandbox (WireMock, http://localhost:8099) stands in for Uzcard and Humo, with test cards for every outcome: see `processing-sandbox/README.md`.
Vault (http://localhost:8200, token `local-only`, dev mode) keeps each API client's request-signing key under `secret/merchants/<client id>`. The bank puts keys there directly; the app only reads them:

```bash
docker compose exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=local-only vault vault kv put secret/merchants/<client id> signingKey=$(openssl rand -base64 32)
```

Dev mode keeps everything in memory, so keys are gone after a restart.
SeaweedFS (http://localhost:8333, S3 API, access key `ecom` / `local-only`) stores files for the file service, the way any S3 would in production.
Temporal, Kafka and the observability stack are added when the system needs them.
