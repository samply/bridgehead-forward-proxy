FROM ubuntu/squid:latest
ADD ./entrypoint.sh /docker/
ADD dont_write_to_disk.conf /etc/squid/conf.d/
RUN mkdir /docker/custom-certs; \
    chmod +x /docker/entrypoint.sh

# This is necessary as the upstream image won't forward a SIGINT/SIGTERM correctly.
STOPSIGNAL SIGKILL

ENTRYPOINT ["/docker/entrypoint.sh"]
