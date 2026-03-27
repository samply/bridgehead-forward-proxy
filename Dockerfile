FROM ubuntu:noble AS build

RUN \
    --mount=type=tmpfs,target=/var/lib/apt/ \
    --mount=type=tmpfs,target=/var/log/ \
    apt-get update && apt-get install -y tinyproxy --no-install-recommends

FROM ubuntu:noble

RUN \
    --mount=type=tmpfs,target=/var/lib/apt/ \
    --mount=type=tmpfs,target=/var/log/ \
    apt-get update && apt-get install -y tinyproxy-bin

ADD ./entrypoint.sh /docker/
COPY --from=build /etc/tinyproxy/tinyproxy.conf /docker/tinyproxy.conf

ENTRYPOINT ["/docker/entrypoint.sh"]
