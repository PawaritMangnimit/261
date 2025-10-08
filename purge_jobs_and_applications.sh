#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking db container status..."
CID="$(docker compose ps -q db || true)"
if [ -z "${CID:-}" ] || [ "$(docker inspect -f '{{.State.Running}}' "$CID" 2>/dev/null || echo false)" != "true" ]; then
  echo "   db is not running. Starting db..."
  docker compose up -d db
fi

echo "==> Waiting for Postgres to be ready..."
# รอให้ db พร้อมรับคำสั่ง
until docker compose exec -T db pg_isready -U campus -d campusjobs >/dev/null 2>&1; do
  printf '.'
  sleep 1
done
echo
echo "==> Truncating tables: applications, jobs (reset identity) ..."
docker compose exec -T db psql -U campus -d campusjobs -c "TRUNCATE TABLE applications, jobs RESTART IDENTITY CASCADE;"
echo "✅ Done. Current jobs/applications are now empty."
