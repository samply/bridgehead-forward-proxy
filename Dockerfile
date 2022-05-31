FROM ubuntu/squid:latest
VOLUME ["/docker/custom-certs"]
COPY ./entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh
ENTRYPOINT ["/docker/entrypoint.sh"]
