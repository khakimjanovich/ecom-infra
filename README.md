# acquiring-infra

Local infrastructure for `acquiring-backend` (Series B, "Build an acquiring system").

```bash
docker compose up -d
```

Brings up Postgres (one schema per module), Redis and Keycloak. Passwords here are for local use only.
Other tools (Vault, Temporal, Kafka, observability) join in the episode whose problem needs them.
