#!/bin/sh
# Puts the app's local-only secrets into the local Vault (dev mode keeps them in memory, so this runs
# on every `docker compose up`). The app reads them through spring.config.import=vault://secret/ecom;
# outside local, the bank writes real values to the same path. Every value here is public.
set -e
until vault status > /dev/null 2>&1; do sleep 1; done

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
