FROM ubuntu/squid:latest
ADD ./entrypoint.sh ./proxify.sh /docker/
RUN apt-get update -y && apt-get install -y \
    proxychains4 \
    && rm -rf /var/lib/apt/lists/*
RUN sed -i 's/^# localnet /localnet /;s/^socks.*$/#http PROXYIP PROXYPORT/' /etc/proxychains4.conf
RUN mkdir /docker/custom-certs; \
    chmod +x /docker/entrypoint.sh /docker/proxify.sh
    
# This is necessary as the upstream image won't forward a SIGINT/SIGTERM correctly.
STOPSIGNAL SIGKILL

ENTRYPOINT ["/docker/entrypoint.sh"]
