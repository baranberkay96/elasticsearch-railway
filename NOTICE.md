# NOTICE: Elasticsearch template

This is a community template. It is not made, endorsed or supported by Elastic N.V. or Railway. Elasticsearch and Kibana are trademarks of Elasticsearch B.V.

## Components

| Component | Source | License | How it is used |
|---|---|---|---|
| Elasticsearch 9.5.7 (`docker.elastic.co/elasticsearch/elasticsearch:9.5.7@sha256:8aa3b18f6a26880f4c2fa1ffb37a48213e201b0b6a1a47412c66b1f5d533de91`) | https://github.com/elastic/elasticsearch | Default distribution under the Elastic License 2.0 (image label `Elastic-License-2.0`); source also under AGPLv3/SSPL | Official image, unmodified, as the base image |
| Kibana 9.5.7 (`docker.elastic.co/kibana/kibana:9.5.7@sha256:e34ecf8da9b5d858cbdff21a9049b4f21ee99e1039933b20c4fbdf8b500eabf5`) | https://github.com/elastic/kibana | Elastic License 2.0 | Official image, unmodified, as the base image |

### Licence caveat (Elastic License 2.0)

Elastic offers AGPLv3 only as an option for the source code; it does not publish AGPL binaries, and the security features used here (x-pack) are ELv2-only. The images are therefore used under ELv2, which permits each deployer to run the software for their own purposes, including commercially. ELv2 does not permit providing the software to third parties as a hosted or managed service, circumventing licence-key functionality, or removing licensing notices. This template only references Elastic's own images; each deployer runs them in their own Railway account.

## Files written for this template

`services/elasticsearch/Dockerfile`, `railway.yml`, `roles.yml`, `railway-elasticsearch.sh`, `railway-es-sync.sh`, `services/kibana/Dockerfile`, `railway-kibana.sh` and the documentation were written for this template and are offered under the MIT License.

## Upstream files checked (tag v9.5.7)

- elasticsearch: `LICENSE.txt` and `licenses/`, `distribution/docker/src/docker/dockerfiles/default/Dockerfile` (UBI base, uid 1000:0, tini entrypoint), `distribution/docker/src/docker/bin/docker-entrypoint.sh` (`ELASTIC_PASSWORD` → keystore `bootstrap.password`, first start only).
- kibana: `src/dev/build/tasks/os_packages/docker_generator/resources/base/bin/kibana-docker` (environment variable whitelist), `config/node.options`.
- Elastic licensing FAQ (default distribution stays under ELv2 after the 2024 AGPL addition).

## Market templates

The Elasticsearch templates on the Railway marketplace (`railwayapp-templates/elasticsearch`, `elasticsearch:9.0.2` + `kibana:9.0.2` with security off, `protemplate/elasticsearch-railway`) were reviewed for features only. No files or text were copied.
