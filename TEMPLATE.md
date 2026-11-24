# TEMPLATE: Elasticsearch 9.5 with Kibana

Composer spec. `template.json` is the machine-readable copy.

## Services

| Field | Elasticsearch | Kibana |
|---|---|---|
| Source | repo `baranberkay96/elasticsearch-railway`, root `/services/elasticsearch` | same repo, root `/services/kibana` |
| Base | `docker.elastic.co/elasticsearch/elasticsearch:9.5.7@sha256:8aa3b18f…` (2026-11-23, 777 MB compressed) | `docker.elastic.co/kibana/kibana:9.5.7@sha256:e34ecf8d…` (552 MB compressed) |
| Public domain | yes, 9200 (login required) | yes, 5601 |
| Healthcheck | `/_cluster/health?wait_for_status=yellow&timeout=5s` (anonymous role, health only), 900 s | `/login`, 1200 s |
| Restart | ALWAYS | ALWAYS |
| Volume | `/usr/share/elasticsearch/data` | - |

Elasticsearch variables: `ELASTIC_USERNAME` elastic (informational), `ELASTIC_PASSWORD` (secret 32), `KIBANA_SYSTEM_PASSWORD` (secret 32), `ELASTICSEARCH_HEAP_MB` empty (auto), `PORT` 9200, `ELASTICSEARCH_URL`, `ELASTICSEARCH_PUBLIC_URL`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` 60.
Kibana variables: `ELASTICSEARCH_HOSTS`, `ELASTICSEARCH_USERNAME` kibana_system, `ELASTICSEARCH_PASSWORD` (reference), `SERVER_PUBLICBASEURL`, three `XPACK_*_ENCRYPTIONKEY` (secret 48), `XPACK_SECURITY_SECURECOOKIES` true, `TELEMETRY_OPTIN` false, `NEWSFEED_ENABLED` false, `PORT` 5601. No required inputs.

## Design

- `railway.yml`: single-node, `http.host: "::"` (quoted in YAML, STANDARD 8.4), `transport.host: 127.0.0.1` (no bootstrap checks), `node.store.allow_mmap: false`, security on, HTTP/transport TLS off (Railway edge TLS, private network), anonymous user with role `railway_health` (`cluster:monitor/health` only, `authz_exception: false` → other requests still 401).
- `railway-elasticsearch` (bash, root): chown volume to 1000:0 on first start, heap 40% of cgroup limit (256-2048 MB) or `ELASTICSEARCH_HEAP_MB`, password checks (12-128, else random = locked), temporary file-realm superuser with a random password, then `chroot --skip-chdir --userspec=1000:0 /` into the upstream `docker-entrypoint.sh` (keeps the working directory, 8.4).
- `railway-es-sync` (background, uid 1000): waits for ES, sets `elastic` and `kibana_system` passwords from the variables, removes the temporary user. Variables stay authoritative after the first boot (upstream only uses `ELASTIC_PASSWORD` once).
- `railway-kibana` (bash): `server.host ::`, short encryption keys → stable SHA-256-derived 64-char key, invalid booleans/URLs → defaults, Node heap 60% of the limit below 2 GB (8.31).

## Improvements over market templates

- The Elasticsearch + Kibana market template runs 9.0.2 with security disabled on public domains (open cluster). Railway's own template has no Kibana, grants anonymous `monitor` (cluster/node stats public), uses `sudo` and a fixed 4 GB max heap. This template pins 9.5.7 by digest, keeps security on with health-only anonymous access, sizes the heap from the plan, keeps passwords in sync with the variables, and includes Kibana with its system user and encryption keys.

## Resources

| Service | Idle RAM | Typical RAM | CPU |
|---|---|---|---|
| Elasticsearch | ES_RAM (measured) | heap + 0.5-1 GB | low idle, bursts on indexing |
| Kibana | KB_RAM (measured) | 0.5-1 GB | low idle |

Estimated cost: ≈$15-30/month for both services at idle-to-light use + volume. Minimum plan: Hobby recommended; Trial (1 GB/service) only for very small data (see measured limits).

## Verification checklist

- ES healthcheck 200 without login; `/` and `/_cat/indices` 401 without, 200 as `elastic`.
- Index a document, search it; data survives a redeploy.
- Kibana `/login` 200; login as `elastic` works; Kibana status green.
- Change `ELASTIC_PASSWORD` → after redeploy only the new password works.
- `ELASTIC_PASSWORD=short` → deploy SUCCESS, account locked, warning; short Kibana key → stable derived key, Kibana starts.

## Open questions

- ELv2 licence caveat (see NOTICE.md) needs the owner's acceptance; OpenSearch would be the Apache-2.0 alternative.
