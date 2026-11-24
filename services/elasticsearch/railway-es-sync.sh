#!/bin/bash
# Background helper: once Elasticsearch answers, set the elastic (and
# kibana_system) passwords from the service variables, then remove the
# temporary file-realm superuser. Secrets are never printed.
set -uo pipefail

log() { echo "railway-es-sync: $*" >&2; }
cd /usr/share/elasticsearch
url="http://127.0.0.1:${PORT:-9200}"
user=$RAILWAY_ES_BOOT_USER pw=$RAILWAY_ES_BOOT_PW kibana_pw=$RAILWAY_ES_KIBANA_PW
unset RAILWAY_ES_BOOT_PW RAILWAY_ES_KIBANA_PW

json_string() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
api() { # method path body -> http status
  curl -s -o /dev/null -w '%{http_code}' --max-time 30 -u "$user:$pw" -X "$1" \
    -H 'Content-Type: application/json' --data-binary @- "$url$2" <<<"$3"
}

for _ in $(seq 1 180); do   # up to 15 minutes
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -u "$user:$pw" "$url/_security/_authenticate" || true)
  [[ "$code" == 200 ]] && break
  sleep 5
done
if [[ "$code" != 200 ]]; then
  log "Elasticsearch did not accept the bootstrap login (HTTP $code); passwords not synced"
  exit 0
fi

status=$(api POST /_security/user/elastic/_password "{\"password\":\"$(json_string "$ELASTIC_PASSWORD")\"}")
log "elastic password applied from ELASTIC_PASSWORD (HTTP $status)"
if [[ -n "$kibana_pw" ]]; then
  status=$(api POST /_security/user/kibana_system/_password "{\"password\":\"$(json_string "$kibana_pw")\"}")
  log "kibana_system password applied from KIBANA_SYSTEM_PASSWORD (HTTP $status)"
fi
bin/elasticsearch-users userdel "$user" >/dev/null 2>&1 && log "temporary bootstrap user removed"
exit 0
