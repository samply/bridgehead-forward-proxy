#!/usr/bin/env bash

OPTIONS=""

echo "Checking for user supplied certificates"
if [ -n "$(ls -A /docker/custom-certs 2>/dev/null)" ]; then
    echo "Found user supplied certificates"
    for file in /docker/custom-certs/*; do
        echo "Importing certificate $file to /usr/local/share/ca-certificates/$(basename $file).crt"
        cp -v $file /usr/local/share/ca-certificates/$(basename $file).crt
    done
    update-ca-certificates || (echo -e "\nThe system has REJECTED one of the certificates:"; ls -l /custom-certs/*; echo "Make sure that ALL of the certificates are valid."; exit 1)
    echo "Successfully imported custom-certs."

    OPTIONS+="tls-cafile=/usr/local/share/ca-certificates/ "

fi


if [ ! -z $PROXY_USERNAME ] || [ ! -z $PROXY_PASSWORD ]; then

    OPTIONS+="login=${PROXY_USERNAME}:${PROXY_PASSWORD} "
fi

if [ ! -z $http_proxy ]; then

PROXY_HOST=$(echo $http_proxy | awk -F "[/:]" '{print $4}' )
PROXY_PORT=$(echo $http_proxy | awk -F "[/:]" '{print $5}' )

echo "cache_peer parent ${PROXY_HOST} ${PROXY_PORT} 0 ${OPTIONS}" ###>>  /etc/squid/squid.conf

fi

##/usr/local/bin/entrypoint.sh -f /etc/squid/squid.conf -NYC
