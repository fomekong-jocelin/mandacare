#!/usr/bin/env bash
# MandaCare backend deployment from Git.
# Server-side workflow: git fetch/reset, Maven build, JAR install, systemd restart.
set -euo pipefail

REPO_URL="${MANDACARE_REPO_URL:-https://github.com/fomekong-jocelin/mandacare.git}"
BRANCH="${MANDACARE_DEPLOY_BRANCH:-main}"
SRC_DIR="${MANDACARE_SRC_DIR:-/root/mandacare-src}"
API_SUBDIR="${MANDACARE_API_SUBDIR:-mandacare-api}"
APP_DIR="${MANDACARE_APP_DIR:-/opt/mandacare/api}"
JAR_TARGET="${APP_DIR}/app.jar"
SERVICE_NAME="${MANDACARE_SERVICE_NAME:-mandacare-api}"
ENV_FILE="${MANDACARE_ENV_FILE:-/etc/mandacare/env}"
BACKUP_DIR="${MANDACARE_BACKUP_DIR:-/root/deploy-backups/mandacare}"
STAMP="$(date +%F-%H%M%S)"

if [ -f "${ENV_FILE}" ]; then
  # shellcheck disable=SC1090
  set -a && . "${ENV_FILE}" && set +a
fi

API_PORT="${MANDACARE_API_PORT:-8082}"
HEALTH_URL="${MANDACARE_HEALTH_URL:-http://127.0.0.1:${API_PORT}/actuator/health}"

echo "=== [1/6] Clone or update source ==="
if [ ! -d "${SRC_DIR}/.git" ]; then
  rm -rf "${SRC_DIR}"
  git clone "${REPO_URL}" "${SRC_DIR}"
fi

cd "${SRC_DIR}"
git fetch origin "${BRANCH}"
git reset --hard "origin/${BRANCH}"

echo "=== [2/6] Build Spring Boot backend ==="
cd "${SRC_DIR}/${API_SUBDIR}"
mvn clean package -DskipTests

JAR_PATH="$(find target -name 'mandacare-api-*.jar' ! -name '*original*' | head -n 1)"
if [ -z "${JAR_PATH}" ]; then
  echo "ERROR: backend JAR not found in target/" >&2
  exit 1
fi
echo "Built JAR: ${JAR_PATH}"

echo "=== [3/6] Backup current JAR ==="
mkdir -p "${BACKUP_DIR}"
if [ -f "${JAR_TARGET}" ]; then
  cp -a "${JAR_TARGET}" "${BACKUP_DIR}/app.jar-${STAMP}.bak"
fi

echo "=== [4/6] Install backend JAR ==="
mkdir -p "${APP_DIR}"
systemctl stop "${SERVICE_NAME}" || true
install -o mandacare -g mandacare -m 640 \
  "${SRC_DIR}/${API_SUBDIR}/${JAR_PATH}" "${JAR_TARGET}"

echo "=== [5/6] Start service ==="
systemctl start "${SERVICE_NAME}"

echo "=== [6/6] Health check ==="
ok=0
for _ in $(seq 1 45); do
  code="$(curl -s -o /tmp/mandacare-health.json -w '%{http_code}' "${HEALTH_URL}" || true)"
  if [ "${code}" = "200" ] && grep -q '"status":"UP"' /tmp/mandacare-health.json 2>/dev/null; then
    ok=1
    break
  fi
  sleep 2
done

systemctl --no-pager -l status "${SERVICE_NAME}" | sed -n '1,40p'

if [ "${ok}" -ne 1 ]; then
  echo "ERROR: API health check failed at ${HEALTH_URL}" >&2
  journalctl -u "${SERVICE_NAME}" -n 80 --no-pager >&2 || true
  exit 1
fi

echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "MandaCare API: ${HEALTH_URL}"
