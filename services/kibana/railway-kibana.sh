#!/bin/bash
# Start Kibana on Railway.
#
# Kibana refuses to start on an encryption key shorter than 32 characters
# or a malformed URL. Deploy-form values must never fail the deploy
# (STANDARD 8.29), so short keys are stretched into a stable 64-character
# key (SHA-256 of the given value) and other bad values fall back to
# defaults, each with a warning in the log.
set -euo pipefail

log() { echo "railway-kibana: $*" >&2; }

if [[ ! "${PORT:-}" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  log "PORT='${PORT:-}' is not usable, using 5601"; PORT=5601
fi
export SERVER_PORT="$PORT" SERVER_HOST="::"   # Node on :: is dual-stack

for name in XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY XPACK_SECURITY_ENCRYPTIONKEY XPACK_REPORTING_ENCRYPTIONKEY; do
  value=${!name:-}
  if (( ${#value} < 32 )); then
    log "WARNING: $name is shorter than 32 characters; using a stable key derived from it. Set 32+ characters."
    value=$(printf '%s/%s' "$name" "$value" | sha256sum | cut -c1-64)
  fi
  export "$name=$value"
done

for pair in TELEMETRY_OPTIN:false NEWSFEED_ENABLED:false XPACK_SECURITY_SECURECOOKIES:true; do
  name=${pair%%:*} default=${pair##*:}
  value=${!name:-}
  value=${value,,}
  if [[ "$value" != true && "$value" != false ]]; then
    [[ -n "$value" ]] && log "$name='$value' is not true/false, using $default"
    value=$default
  fi
  export "$name=$value"
done

if [[ ! "${SERVER_PUBLICBASEURL:-}" =~ ^https?://[^/[:space:]]+$ ]]; then
  [[ -n "${SERVER_PUBLICBASEURL:-}" ]] && log "SERVER_PUBLICBASEURL='${SERVER_PUBLICBASEURL}' is not a URL like https://host (no path), ignoring it"
  unset SERVER_PUBLICBASEURL
fi
if [[ ! "${ELASTICSEARCH_HOSTS:-}" =~ ^https?:// ]]; then
  log "WARNING: ELASTICSEARCH_HOSTS='${ELASTICSEARCH_HOSTS:-}' is not an http(s) URL; using http://elasticsearch.railway.internal:9200"
  export ELASTICSEARCH_HOSTS=http://elasticsearch.railway.internal:9200
fi
if [[ -z "${ELASTICSEARCH_PASSWORD:-}" ]]; then
  log "WARNING: ELASTICSEARCH_PASSWORD (kibana_system) is empty; Kibana cannot connect until it is set."
fi

# Kibana needs roughly 1.5-2 GB; below 2 GB give Node 75 % of the limit and say so (STANDARD 8.31).
limit=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
if [[ "$limit" =~ ^[0-9]+$ ]] && (( limit < 2 * 1024 * 1024 * 1024 )) && [[ "${NODE_OPTIONS:-}" != *max-old-space-size* ]]; then
  heap=$(( limit / 1048576 * 75 / 100 ))
  export NODE_OPTIONS="--max-old-space-size=$heap ${NODE_OPTIONS:-}"
  log "WARNING: memory limit $(( limit / 1048576 )) MB is below the ~2 GB Kibana needs; Node heap set to $heap MB"
fi

log "starting Kibana on [::]:$PORT, Elasticsearch at $ELASTICSEARCH_HOSTS"
exec /usr/local/bin/kibana-docker
