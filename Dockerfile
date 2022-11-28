FROM ubuntu/squid:latest
ADD ./entrypoint.sh ./proxify.sh /docker/
RUN apt-get update -y && apt-get install -y \
    proxychains4 \
    && rm -rf /var/lib/apt/lists/*
RUN sed -i 's/^# localnet /localnet /;s/^socks.*$/#http PROXYIP PROXYPORT/' /etc/proxychains4.conf
RUN chmod +x /docker/entrypoint.sh /docker/proxify.sh
ENTRYPOINT ["/docker/entrypoint.sh"]
