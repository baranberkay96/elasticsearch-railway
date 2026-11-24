# syntax=docker/dockerfile:1
#
# Kibana 9.5.7 (Elastic License 2.0) for Railway.
#
# Base: the official image from docker.elastic.co, multi-arch index digest
# checked 2026-11-24. Keep it on the same version as Elasticsearch.
FROM docker.elastic.co/kibana/kibana:9.5.7@sha256:e34ecf8da9b5d858cbdff21a9049b4f21ee99e1039933b20c4fbdf8b500eabf5

COPY --chmod=0755 railway-kibana.sh /usr/local/bin/railway-kibana

ENV PORT=5601
EXPOSE 5601

ENTRYPOINT ["/usr/local/bin/railway-kibana"]
