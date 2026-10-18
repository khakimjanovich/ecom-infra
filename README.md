# ecom-infra

Local infrastructure for [ecom](https://github.com/khakimjanovich/ecom).

```bash
docker compose up -d
```

Brings up Postgres (one schema and one user per module, e.g. `partner_user` sees only `partner`), Redis and Keycloak. Passwords here are for local use only.
Vault, Temporal, Kafka and the observability stack are added when the system needs them.
