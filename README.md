# Deploy and Host Elasticsearch with Railway

Elasticsearch is the distributed search and analytics engine behind the Elastic Stack: full-text search, vector and hybrid search, log and metrics analytics, and aggregations over large data sets through a REST API. This template runs Elasticsearch 9.5 with security and logins switched on, plus Kibana for exploring data and managing the cluster.

## About Hosting Elasticsearch

Elasticsearch is a JVM service that needs a persistent data volume, a heap sized for its container, and real authentication before it is reachable from the internet. Kibana needs its own system user and encryption keys. This community template builds the official Elastic images (pinned by digest) with small start scripts that fix the volume ownership, size the heap from the service's memory limit, run single-node without the production bootstrap checks Railway hosts cannot satisfy, and apply the `elastic` and `kibana_system` passwords from the service variables on every start. Unauthenticated requests can only read cluster health (used by Railway's healthcheck); everything else asks for a login.

## Common Use Cases

- Full-text, vector or hybrid search for apps, sites and product catalogs
- Log, event and metrics analytics with Kibana dashboards (Beats, Elastic Agent, Logstash, OpenTelemetry)
- Search backend for RAG and AI applications (dense vectors, kNN, semantic text)
- A private development or staging copy of a production Elastic stack

## Dependencies for Elasticsearch Hosting

- Elasticsearch 9.5.7 (official image) with a Railway volume for its data
- Kibana 9.5.7 (official image), connected over Railway's private network

### Deployment Dependencies

- [Elasticsearch documentation](https://www.elastic.co/docs/solutions/search)
- [Elasticsearch Docker setup](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-docker-basic)
- [Kibana documentation](https://www.elastic.co/docs/explore-analyze)
- [Elastic License 2.0](https://www.elastic.co/licensing/elastic-license)

### Implementation Details

| Service | What runs inside | Volume | Port |
|---|---|---|---|
| Elasticsearch | Elasticsearch 9.5.7, single node, security on | `/usr/share/elasticsearch/data` | 9200, public domain (login required) |
| Kibana | Kibana 9.5.7 | - | 5601, public domain (login page) |

**First login**

1. Wait until both services are green (Elasticsearch first, Kibana a minute or two later).
2. Open the **Kibana** domain and log in as `elastic` with `ELASTIC_PASSWORD` from the Elasticsearch service's Variables tab.
3. Create users and roles with fewer rights under Stack Management, Security, and use those for your apps.

**Using the API**

- `curl -u elastic:{password} https://{elasticsearch-domain}/` returns the cluster info; create an API key with `POST /_security/api_key` for applications.
- Other Railway services connect privately with `${{Elasticsearch.ELASTICSEARCH_URL}}` (for example `http://elasticsearch.railway.internal:9200`) and a user or API key. The official Elasticsearch clients work with plain HTTP and basic or API-key auth.

**Passwords and keys**

`ELASTIC_PASSWORD` and `KIBANA_SYSTEM_PASSWORD` are applied at every start, so the variables stay the source of truth: change a variable and redeploy (a password changed only in Kibana is reset on the next start). A password shorter than 12 characters locks that account with a random one and the log says how to fix it. Kibana's three encryption keys are generated; keep `XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY` unchanged once Kibana holds alerting rules or connectors.

**Memory and scaling**

The JVM heap is 40% of the Elasticsearch service's memory limit (256-2048 MB) unless you set `ELASTICSEARCH_HEAP_MB`; the rest is used by Lucene and the file cache. On the Trial plan (1 GB per service) the heap is about 380 MB, enough for small indexes; give the service more memory for real workloads and raise the heap to about half of it. Kibana caps its Node heap below 2 GB of memory. This template is a single node (indexes get one shard and no replicas, so cluster health is yellow for indexes created with replicas); scale vertically. Memory mapping is off (`node.store.allow_mmap: false`) because Railway cannot raise `vm.max_map_count`.

**Upgrades**

Eject the repo, change the tag and digest in both `services/*/Dockerfile` files to the same new version, read Elastic's upgrade notes, take a snapshot, and redeploy Elasticsearch before Kibana.

**Backups**

Register a snapshot repository (for example S3 on a Railway Bucket with the `repository-s3` settings) and use Snapshot and Restore in Kibana. Snapshots on the data volume do not protect against losing the volume.

**Licence**

Elastic publishes the source of Elasticsearch and Kibana under AGPLv3, SSPL or the Elastic License 2.0 (ELv2), but the official binaries and images used here are the default distribution under ELv2 with the free Basic features. ELv2 allows you to run them for your own applications, including commercial ones. It does not allow offering Elasticsearch or Kibana to third parties as a hosted or managed service, or circumventing licence keys. If you need an Apache-2.0 engine, use OpenSearch instead.

### Why Deploy Elasticsearch on Railway?

Railway gives Elasticsearch what it needs without cluster management: a persistent volume, memory you can raise with a slider, HTTPS on public domains and a private network for your apps and Kibana. You get a secured single-node Elastic stack in a few minutes and pay for what it uses. This is a community template, not affiliated with Elastic.
