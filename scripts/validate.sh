#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo '==> Validating Docker Compose syntax'
sudo docker compose config -q

echo '==> Checking required Kometa secrets are injected'
sudo docker compose run --rm --entrypoint sh kometa -c '
  missing=0
  for var in KOMETA_plextoken KOMETA_tmdbkey KOMETA_notifiarrkey; do
    eval "value=\${$var:-}"
    if [ -z "$value" ]; then
      echo "Missing required environment variable: $var" >&2
      missing=1
    fi
  done
  exit "$missing"
'

echo '==> Running full Kometa validation'
sudo docker compose run --rm kometa \
  --validate \
  --validate-level full

echo '==> Checking whether this Docker image contains JSON schemas'
if sudo docker compose run --rm --entrypoint sh kometa -c 'test -d /json-schema'; then
  echo '==> Running JSON schema validation'
  sudo docker compose run --rm kometa \
    --validate \
    --validate-level full \
    --validate-schemas \
    --schema-path /json-schema

  echo '==> Validating every YAML file under /config against schemas'
  sudo docker compose run --rm kometa \
    --validate-dir /config \
    --schema-path /json-schema
else
  echo '==> JSON schemas are not present in this Kometa Docker image; skipping schema-only checks'
fi

echo '==> Validation completed successfully'
