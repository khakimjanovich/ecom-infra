# acquiring-infra

Local infrastructure for `acquiring-backend` (Series B, "Build an acquiring system").

```bash
docker compose up -d
```

Brings up Postgres (one schema and one user per module, e.g. `partner_user` sees only `partner`), Redis and Keycloak. Passwords here are for local use only.
Other tools (Vault, Temporal, Kafka, observability) join in the episode whose problem needs them.
