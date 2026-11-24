# TEMPLATE: Elasticsearch 9.5 Search Engine

Composer spec. `template.json` is the machine-readable copy.

## Service

| Field | Value |
|---|---|
| Name | Elasticsearch |
| Source | repo `baranberkay96/elasticsearch-railway`, root `/services/elasticsearch` |
| Base | `docker.elastic.co/elasticsearch/elasticsearch:9.5.7@sha256:8aa3b18f…` (2026-11-23, 777 MB compressed) |
| Public domain | yes, 9200 (login required except cluster health) |
| Healthcheck | `/_cluster/health?wait_for_status=yellow&timeout=5s` (anonymous role, health only), 900 s |
| Restart | ALWAYS |
| Volume | `/usr/share/elasticsearch/data` |

Variables: `ELASTIC_USERNAME` elastic (informational), `ELASTIC_PASSWORD` (secret 32), `ELASTICSEARCH_HEAP_MB` empty (auto), `PORT` 9200, `ELASTICSEARCH_URL`, `ELASTICSEARCH_PUBLIC_URL`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` 60. No required inputs.

Optional add-on (not deployed): `services/kibana` (Kibana 9.5.7 `@sha256:e34ecf8d…`, 552 MB compressed) with `railway-kibana.sh`; setup steps in the README.

## Design

- `railway.yml`: single-node, `http.host: "::"` (quoted in YAML, STANDARD 8.4), `transport.host: 127.0.0.1` (no bootstrap checks), `node.store.allow_mmap: false` (no `vm.max_map_count` on Railway), security on, HTTP/transport TLS off (Railway edge TLS, private network), anonymous user with role `railway_health` (`cluster:monitor/health` only, `authz_exception: false` → other requests still 401 with a Basic challenge).
- `railway-elasticsearch` (bash, root): chown volume to 1000:0 on first start, heap 40% of the cgroup limit (256-1024 MB) or `ELASTICSEARCH_HEAP_MB`, password check (12-128, else random = locked), temporary file-realm superuser with a random password, then `chroot --skip-chdir --userspec=1000:0 /` into the upstream `docker-entrypoint.sh` (keeps the working directory, 8.4).
- `railway-es-sync` (background, uid 1000): waits for ES, sets the `elastic` password (and `kibana_system` if `KIBANA_SYSTEM_PASSWORD` is set) from the variables, removes the temporary user. Upstream only uses `ELASTIC_PASSWORD` on the very first boot.
- Kibana dropped from the default template: it crash-looped with Node heap OOM under a 1 GB limit and used ~1.8 GB unconstrained (8.31).

## Improvements over market templates

- The Elasticsearch + Kibana market template runs 9.0.2 with security disabled on public domains (open cluster). Railway's own template grants anonymous `monitor` (cluster/node stats public), uses `sudo` and a fixed 4 GB max heap. This template pins 9.5.7 by digest, keeps security on with health-only anonymous access, sizes the heap from the plan, and keeps the password in sync with the variable.

## Resources

| Service | Idle RAM | Typical RAM | CPU |
|---|---|---|---|
| Elasticsearch | ES_RAM | heap + 0.5-1 GB | low idle, bursts on indexing |

ES pre-touches its heap (`-XX:+AlwaysPreTouch` in the image's jvm.options), so idle RAM ≈ heap + 0.45 GB. Estimated cost: ≈$8-16/month idle + volume. Minimum plan: Trial for small indexes (measured 0.83 GB under the 1 GB cap); not Free (0.5 GB).

## Verification checklist

- Healthcheck 200 without login; `/`, `/_cat/indices`, `/_nodes/stats` 401 without, 200 as `elastic`.
- Index a document, fuzzy search; data survives a redeploy.
- Change `ELASTIC_PASSWORD` → after redeploy only the new password works.
- `ELASTIC_PASSWORD=short` → deploy SUCCESS, account locked, warning.

## Open questions

- ELv2 licence caveat (see NOTICE.md) needs the owner's acceptance; OpenSearch would be the Apache-2.0 alternative.
- An "Elasticsearch + Kibana" variant for Hobby/Pro (≈3.5 GB idle) could be a separate listing.
