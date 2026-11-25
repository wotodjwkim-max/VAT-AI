
#!/usr/bin/env bash
set -Eeuo pipefail

echo "[startup] Running database migrations"
alembic upgrade head

echo "[startup] Starting OCR worker"
python -m app.jobs.worker &
WORKER_PID=$!

echo "[startup] Starting FastAPI"
uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-10000}" &
API_PID=$!

cleanup() {
  echo "[startup] Stopping services"
  kill "$WORKER_PID" "$API_PID" 2>/dev/null || true
  wait "$WORKER_PID" "$API_PID" 2>/dev/null || true
}

trap cleanup EXIT
trap 'exit 143' TERM INT

set +e
wait -n "$WORKER_PID" "$API_PID"
STATUS=$?
set -e

echo "[startup] A process exited: $STATUS"
exit "${STATUS:-1}"
  
