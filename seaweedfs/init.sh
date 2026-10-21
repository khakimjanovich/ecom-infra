#!/bin/sh
# Creates the app's buckets: they are infrastructure, the app only checks that they exist. Runs on
# every `docker compose up`; a bucket that exists already stays as it is. `weed shell` exits 0 even
# when a command fails (e.g. the filer isn't up yet), so each bucket is created until it is listed.
MASTER=file-store:9333
for bucket in partner-documents sales-point-logos; do
  tries=0
  until echo "s3.bucket.list" | weed shell -master=$MASTER 2>/dev/null | grep -qE "[[:space:]]$bucket[[:space:]]"; do
    tries=$((tries + 1))
    if [ "$tries" -gt 60 ]; then echo "bucket $bucket: not created" >&2; exit 1; fi
    echo "s3.bucket.create -name $bucket" | weed shell -master=$MASTER > /dev/null 2>&1
    sleep 1
  done
  echo "bucket $bucket ready"
done
