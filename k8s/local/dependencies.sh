#!/usr/bin/env sh
# The compose containers the cluster calls, as Kubernetes Services with fixed endpoints: inside the
# cluster "postgres:5432" means the compose stack's Postgres, as a managed database would in
# production. Run after the main stack starts (container addresses change on restart):
#   k8s/local/dependencies.sh | docker exec -i ecom-k8s-k3s-1 kubectl apply -f -
set -eu
for entry in postgres:5432 redis:6379 mailpit:1025 keycloak:8080 vault:8200 temporal:7233 \
  kafka:9092 processing-sandbox:8080 file-store:8333; do
  name=${entry%%:*}
  port=${entry##*:}
  ip=$(docker inspect -f '{{(index .NetworkSettings.Networks "ecom_default").IPAddress}}' "ecom-$name-1")
  cat <<YAML
---
apiVersion: v1
kind: Service
metadata: { name: $name, namespace: ecom }
spec:
  ports: [{ port: $port, targetPort: $port }]
---
apiVersion: v1
kind: Endpoints
metadata: { name: $name, namespace: ecom }
subsets:
  - addresses: [{ ip: $ip }]
    ports: [{ port: $port }]
YAML
done
