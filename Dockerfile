FROM ubuntu:noble

RUN \
    --mount=type=tmpfs,target=/var/lib/apt/ \
    --mount=type=tmpfs,target=/var/log/ \
    apt-get update && apt-get install -y tinyproxy-bin

ADD ./entrypoint.sh /docker/

ENTRYPOINT ["/docker/entrypoint.sh"]
