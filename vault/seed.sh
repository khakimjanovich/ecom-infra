#!/bin/sh
# Puts the app's local-only secrets into the local Vault (dev mode keeps them in memory, so this runs
# on every `docker compose up`). The app reads them through spring.config.import=vault://secret/ecom;
# outside local, the bank writes real values to the same path. Every value here is public.
set -e
# Vault answers within seconds; after a minute something is wrong, and `docker compose up` says so.
tries=0
until vault status > /dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -ge 60 ]; then
    echo "vault-seed: Vault at $VAULT_ADDR did not answer in 60 s" >&2
    exit 1
  fi
  sleep 1
done

vault kv put secret/ecom \
  ecom.crypto.active-key-id=local1 \
  ecom.crypto.keys.local1=bG9jYWwtb25seS1rZXktZm9yLWNhcmQtZGF0YS1rMSE= \
  ecom.crypto.blind-index-key=bG9jYWwtb25seS1ibGluZC1pbmRleC1rZXktMDAwMSE= \
  ecom.otp.secret=local-only-otp-secret \
  ecom.keycloak.client-secret=local-only \
  ecom.file-store.storage.secret-key=local-only \
  ecom.db.partner.password=local-only \
  ecom.db.commission.password=local-only \
  ecom.db.epos.password=local-only \
  ecom.db.bin.password=local-only \
  ecom.db.card.password=local-only \
  ecom.db.payment.password=local-only
