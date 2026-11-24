# Deploy and Host Elasticsearch with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/elasticsearch-95-search-engine?referralCode=20H68q)

Elasticsearch is the distributed search and analytics engine behind the Elastic Stack: full-text search, vector and hybrid search, log and metrics analytics, and aggregations over large data sets through a REST API. This template runs Elasticsearch 9.5 as a secured single node with a generated `elastic` password; Kibana can be added from the same repo.

## About Hosting Elasticsearch

Elasticsearch is a JVM service that needs a persistent data volume, a heap sized for its container, and real authentication before it is reachable from the internet. This community template builds the official Elastic images (pinned by digest) with small start scripts that fix the volume ownership, size the heap from the service's memory limit, run single-node without the production bootstrap checks Railway hosts cannot satisfy, and apply the `elastic` password from the service variables on every start. Unauthenticated requests can only read cluster health (used by Railway's healthcheck); everything else asks for a login.

## Common Use Cases

- Full-text, vector or hybrid search for apps, sites and product catalogs
- Log, event and metrics storage and analytics (Beats, Elastic Agent, Logstash, OpenTelemetry), with Kibana as an add-on
- Search backend for RAG and AI applications (dense vectors, kNN, semantic text)
- A private development or staging copy of a production Elastic stack

## Dependencies for Elasticsearch Hosting

- Elasticsearch 9.5.7 (official image) with a Railway volume for its data
- Optional: Kibana 9.5.7 from `services/kibana` in the same repo (about 2 GB RAM)

### Deployment Dependencies

- [Elasticsearch documentation](https://www.elastic.co/docs/solutions/search)
- [Elasticsearch Docker setup](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-docker-basic)
- [Kibana documentation](https://www.elastic.co/docs/explore-analyze)
- [Elastic License 2.0](https://www.elastic.co/licensing/elastic-license)

### Implementation Details

| Service | What runs inside | Volume | Port |
|---|---|---|---|
| Elasticsearch | Elasticsearch 9.5.7, single node, security on | `/usr/share/elasticsearch/data` | 9200, public domain (login required) |

**First steps**

1. Wait until the service is green (first start takes one to three minutes).
2. Check `https://{your-domain}/_cluster/health` (no login needed; it is the only open endpoint).
3. `curl -u elastic:{password} https://{your-domain}/` with `ELASTIC_PASSWORD` from the Variables tab returns the cluster info. Create users, roles and API keys with fewer rights for your apps (`POST /_security/api_key`).

**Using the API**

- `curl -u elastic:{password} https://{elasticsearch-domain}/` returns the cluster info; create an API key with `POST /_security/api_key` for applications.
- Other Railway services connect privately with `${{Elasticsearch.ELASTICSEARCH_URL}}` (for example `http://elasticsearch.railway.internal:9200`) and a user or API key. The official Elasticsearch clients work with plain HTTP and basic or API-key auth.

**Password**

`ELASTIC_PASSWORD` is applied at every start, so the variable stays the source of truth: change it and redeploy (a password changed only through the API is reset on the next start). A password shorter than 12 characters locks the `elastic` account with a random one and the log says how to fix it.

**Adding Kibana (optional)**

Kibana used about 1.8 GB on Railway and ran out of Node heap under the Trial plan's 1 GB, so it is not deployed by default. To add it on Hobby or Pro: Eject the repo, add `KIBANA_SYSTEM_PASSWORD` (16+ random characters) to the Elasticsearch service and redeploy it (the start script then sets the `kibana_system` password), and create a service from your repo with root directory `/services/kibana`, a public domain on port 5601, healthcheck `/login`, and the variables `ELASTICSEARCH_HOSTS=http://${{Elasticsearch.RAILWAY_PRIVATE_DOMAIN}}:9200`, `ELASTICSEARCH_USERNAME=kibana_system`, `ELASTICSEARCH_PASSWORD=${{Elasticsearch.KIBANA_SYSTEM_PASSWORD}}`, `SERVER_PUBLICBASEURL=https://${{RAILWAY_PUBLIC_DOMAIN}}` and three 32+ character keys `XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY`, `XPACK_SECURITY_ENCRYPTIONKEY`, `XPACK_REPORTING_ENCRYPTIONKEY`. Log in to Kibana as `elastic`.

**Memory and scaling**

The JVM heap is 40% of the service's memory limit, between 256 and 1024 MB, unless you set `ELASTICSEARCH_HEAP_MB`; Elasticsearch pre-touches the whole heap, so idle RAM is roughly heap + 0.5 GB. Measured on Railway: about 0.8 GB under the Trial plan's 1 GB limit (heap 381 MB, small indexes only) and about 1.6 GB with the default 1 GB heap on larger plans (both measured). For real workloads give the service more memory and set the heap to about half of it. The Free plan (0.5 GB) is too small for Elasticsearch. This template is a single node (new indexes default to one replica, which a single node cannot place, so cluster health shows yellow; set `number_of_replicas: 0` on your indexes for green); scale vertically. Memory mapping is off (`node.store.allow_mmap: false`) because Railway cannot raise `vm.max_map_count`.

**Upgrades**

Eject the repo, change the tag and digest in `services/elasticsearch/Dockerfile` (and `services/kibana/Dockerfile` if you use Kibana, same version), read Elastic's upgrade notes, take a snapshot, and redeploy Elasticsearch first.

**Backups**

Register a snapshot repository (for example S3 on a Railway Bucket with the `repository-s3` settings) and use the snapshot API (`PUT /_snapshot/...`) or Kibana's Snapshot and Restore. Snapshots on the data volume do not protect against losing the volume.

**Licence**

Elastic publishes the source of Elasticsearch and Kibana under AGPLv3, SSPL or the Elastic License 2.0 (ELv2), but the official binaries and images used here are the default distribution under ELv2 with the free Basic features. ELv2 allows you to run them for your own applications, including commercial ones. It does not allow offering Elasticsearch or Kibana to third parties as a hosted or managed service, or circumventing licence keys. If you need an Apache-2.0 engine, use OpenSearch instead.

### Why Deploy Elasticsearch on Railway?

Railway gives Elasticsearch what it needs without cluster management: a persistent volume, memory you can raise with a slider, HTTPS on a public domain and a private network for your apps. You get a secured single-node Elasticsearch in a few minutes and pay for what it uses. This is a community template, not affiliated with Elastic.
