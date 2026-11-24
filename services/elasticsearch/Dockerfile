# syntax=docker/dockerfile:1
#
# Elasticsearch 9.5.7 (default distribution, Elastic License 2.0) for Railway.
#
# Base: the official image from docker.elastic.co, multi-arch index digest
# checked 2026-11-24. To upgrade, change tag and digest together (keep
# Kibana on the same version) after reading the release notes.
FROM docker.elastic.co/elasticsearch/elasticsearch:9.5.7@sha256:8aa3b18f6a26880f4c2fa1ffb37a48213e201b0b6a1a47412c66b1f5d533de91

USER 0
COPY --chmod=0644 railway.yml /usr/share/elasticsearch/config/elasticsearch.yml
COPY --chmod=0644 roles.yml /usr/share/elasticsearch/config/roles.yml
COPY --chmod=0755 railway-elasticsearch.sh /usr/local/bin/railway-elasticsearch
COPY --chmod=0755 railway-es-sync.sh /usr/local/bin/railway-es-sync
RUN chown 1000:0 /usr/share/elasticsearch/config/elasticsearch.yml /usr/share/elasticsearch/config/roles.yml

ENV PORT=9200
EXPOSE 9200

# Runs as root only to fix the volume's ownership, then drops to uid 1000.
ENTRYPOINT ["/usr/local/bin/railway-elasticsearch"]
