#!/bin/bash
# Start Elasticsearch on Railway (runs as root, drops to uid 1000).
#
# - Fixes the ownership of the Railway volume (mounted root-owned).
# - Sizes the JVM heap from the service's memory limit.
# - Makes ELASTIC_PASSWORD (and KIBANA_SYSTEM_PASSWORD) the source of truth
#   on every start: a temporary file-realm superuser with a random password
#   lets railway-es-sync set them through the API, then it is removed.
# - Bad deploy-form values never stop the deploy (STANDARD 8.29): they fall
#   back to defaults; a missing/short password locks the account with a
#   random one and the log says how to fix it.
set -euo pipefail

log() { echo "railway-elasticsearch: $*" >&2; }
ES_HOME=/usr/share/elasticsearch
cd "$ES_HOME"
as_es() { chroot --skip-chdir --userspec=1000:0 / "$@"; }
random_secret() { head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c "$1"; }

# --- port -------------------------------------------------------------------
if [[ ! "${PORT:-}" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )) || [[ "$PORT" == 9300 ]]; then
  log "PORT='${PORT:-}' is not usable, using 9200"; PORT=9200
fi
export PORT ES_SETTING_HTTP_PORT="$PORT"

# --- data volume ------------------------------------------------------------
DATA="${RAILWAY_VOLUME_MOUNT_PATH:-$ES_HOME/data}"
mkdir -p "$DATA"
if [[ "$(stat -c %u "$DATA")" != 1000 ]]; then
  log "giving $DATA to uid 1000 (first start on this volume)"
  chown -R 1000:0 "$DATA"
fi
chmod 0770 "$DATA"
export ES_SETTING_PATH_DATA="$DATA"

# --- heap ---------------------------------------------------------------------
if [[ "${ES_JAVA_OPTS:-}" != *-Xmx* ]]; then
  heap=""
  if [[ -n "${ELASTICSEARCH_HEAP_MB:-}" ]]; then
    if [[ "$ELASTICSEARCH_HEAP_MB" =~ ^[0-9]+$ ]] && (( ELASTICSEARCH_HEAP_MB >= 128 )); then
      heap=$ELASTICSEARCH_HEAP_MB
    else
      log "ELASTICSEARCH_HEAP_MB='$ELASTICSEARCH_HEAP_MB' is not a number >= 128, sizing automatically"
    fi
  fi
  if [[ -z "$heap" ]]; then
    limit=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
    if [[ "$limit" =~ ^[0-9]+$ ]]; then
      heap=$(( limit / 1048576 * 40 / 100 ))   # 40 %: the rest is off-heap, Lucene and page cache
    else
      heap=1024
    fi
    (( heap < 256 )) && heap=256
    (( heap > 2048 )) && heap=2048
  fi
  export ES_JAVA_OPTS="-Xms${heap}m -Xmx${heap}m ${ES_JAVA_OPTS:-}"
  log "JVM heap ${heap} MB (ELASTICSEARCH_HEAP_MB overrides)"
fi

# --- passwords ----------------------------------------------------------------
check_password() { # name -> prints a usable password
  local name=$1 value=${!1:-}
  if (( ${#value} < 12 || ${#value} > 128 )); then
    log "WARNING: $name must be 12-128 characters (got ${#value})."
    log "WARNING: the account is LOCKED with a random password nobody knows; set $name and redeploy."
    random_secret 40
  else
    printf '%s' "$value"
  fi
}
ELASTIC_PASSWORD=$(check_password ELASTIC_PASSWORD)
export ELASTIC_PASSWORD   # first start: docker-entrypoint stores it as bootstrap.password
KIBANA_PW=""
if [[ -n "${KIBANA_SYSTEM_PASSWORD:-}" ]]; then KIBANA_PW=$(check_password KIBANA_SYSTEM_PASSWORD); fi
unset KIBANA_SYSTEM_PASSWORD

# --- temporary superuser for the password sync ----------------------------------
BOOT_USER=railway-bootstrap
BOOT_PW=$(random_secret 40)
as_es bin/elasticsearch-users userdel "$BOOT_USER" >/dev/null 2>&1 || true
as_es bin/elasticsearch-users useradd "$BOOT_USER" -p "$BOOT_PW" -r superuser >/dev/null

RAILWAY_ES_BOOT_USER="$BOOT_USER" RAILWAY_ES_BOOT_PW="$BOOT_PW" RAILWAY_ES_KIBANA_PW="$KIBANA_PW" \
  HOME="$ES_HOME" as_es /usr/local/bin/railway-es-sync &
unset BOOT_PW KIBANA_PW

log "starting Elasticsearch on [::]:$PORT, data in $DATA"
export HOME="$ES_HOME"
exec chroot --skip-chdir --userspec=1000:0 / /usr/local/bin/docker-entrypoint.sh eswrapper
