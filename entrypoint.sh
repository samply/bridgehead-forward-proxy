#!/usr/bin/env bash

OPTIONS=""

echo "Checking for user supplied certificates"
if [ -n "$(ls -A /docker/custom-certs 2>/dev/null)" ]; then
    echo "Found user supplied certificates"
    for file in /docker/custom-certs/*; do
        echo "Importing certificate $file to /usr/local/share/ca-certificates/$(basename $file).crt"
        cp -v $file /usr/local/share/ca-certificates/$(basename $file).crt
        OPTIONS+="tls-cafile=/usr/local/share/ca-certificates/$(basename $file).crt"
    done
    update-ca-certificates || (echo -e "\nThe system has REJECTED one of the certificates:"; ls -l /custom-certs/*; echo "Make sure that ALL of the certificates are valid."; exit 1)
    echo "Successfully imported custom-certs."
fi

if [ ! -z $http_proxy ]; then

    ## All credit to https://stackoverflow.com/a/6174447
    # extract the protocol
    PROTO="$(echo $http_proxy | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    # remove the protocol
    URL="$(echo ${http_proxy/$PROTO/})"
    # extract the user (if any)
    USERPW="$(echo $URL | grep @ | cut -d@ -f1)"
    # extract the host and port
    HOSTPORT="$(echo ${URL/$USERPW@/} | cut -d/ -f1)"
    # by request host without port    
    HOST="$(echo $HOSTPORT | sed -e 's,:.*,,g')"
    # by request - try to extract the port
    PORT="$(echo $HOSTPORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

    if [ ! -z $USERPW ]; then
        OPTIONS+="login=${USERPW} "
    fi

    echo "cache_peer parent ${HOST} ${PORT} 0 ${OPTIONS}" >>  /etc/squid/squid.conf
fi

/usr/local/bin/entrypoint.sh -f /etc/squid/squid.conf -NYC
