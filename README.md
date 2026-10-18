# ecom-infra

Local infrastructure for [ecom](https://github.com/khakimjanovich/ecom).

```bash
docker compose up -d
```

Brings up Postgres (one schema and one user per module, e.g. `partner_user` sees only `partner`), Redis, Mailpit (a local SMTP server; read the emails at http://localhost:8025) and Keycloak (http://localhost:8180, realm `ecom`: roles `admin` and `partner`, admins `aziz` and `malika`, the `ecom-backend` service client and the `ecom-portal` login client). Passwords here are for local use only.
Temporal, Kafka and the observability stack are added when the system needs them.
