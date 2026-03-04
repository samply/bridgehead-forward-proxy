#!/usr/bin/env bash

urldecode() {
    local output=""
    local i=0
    local len=${#1}

    while (( i < len )); do
        local c="${1:i:1}"

        if [[ "$c" == "%" && $((i+2)) -lt len ]]; then
            local hex="${1:i+1:2}"
            if [[ "$hex" =~ ^[0-9A-Fa-f]{2}$ ]]; then
                output+=$(printf "\\x$hex")
                ((i+=3))
                continue
            fi
        fi
	output+="$c"

        ((i++))
    done
    printf '%s' "$output"
}

OPTIONS=""

echo "Checking for user supplied certificates"
if [ -n "$(ls -A /docker/custom-certs/*.pem 2>/dev/null)" ]; then
    echo "Found user supplied certificates"
    for file in /docker/custom-certs/*.pem; do
        echo "Importing certificate $file to /usr/local/share/ca-certificates/$(basename $file).crt"
        cp -v $file /usr/local/share/ca-certificates/$(basename $file).crt
        OPTIONS+="tls-cafile=/usr/local/share/ca-certificates/$(basename $file).crt"
    done
    update-ca-certificates || (echo -e "\nThe system has REJECTED one of the certificates:"; ls -l /custom-certs/*; echo "Make sure that ALL of the certificates are valid."; exit 1)
    echo "Successfully imported custom-certs."
fi

: ${https_proxy:=$HTTPS_PROXY}
: ${https_proxy:=$HTTP_PROXY}
: ${https_proxy:=$http_proxy}

if [ ! -z $https_proxy ]; then

    echo "Configuring proxy $https_proxy"
    ## All credit to https://stackoverflow.com/a/6174447
    # extract the protocol
    PROTO="$(echo $https_proxy | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    # remove the protocol
    URL="$(echo ${https_proxy/$PROTO/})"
    # extract the user and password (if any)
    USERPW="$(echo $URL | grep @ | cut -d@ -f1)"
    # extract the user
    PROXY_USERNAME="$(echo $USERPW | cut -d: -f1)"
    # extract the password
    PROXY_PASSWORD="$(echo $USERPW | cut -d: -f2)"
    # extract the host and port
    HOSTPORT="$(echo ${URL/$USERPW@/} | cut -d/ -f1)"
    # by request host without port
    HOST="$(echo $HOSTPORT | sed -e 's,:.*,,g')"
    # by request - try to extract the port
    PORT="$(echo $HOSTPORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

    if [ ! -z $HTTPS_PROXY_PASSWORD ]; then
        PROXY_PASSWORD=$HTTPS_PROXY_PASSWORD
        PROXY_USERNAME=$HTTPS_PROXY_USERNAME
    fi


    SQUID_LINE="cache_peer $HOST parent $PORT 0 no-query default"

    if [ ! -z $PROXY_PASSWORD ]; then
        echo "Using proxy at $HOST:$PORT with username $PROXY_USERNAME and password (hidden)."
        PROXY_PASSWORD_ESCAPED=$(urldecode "$PROXY_PASSWORD")
    	SQUID_LINE+=" login=$PROXY_USERNAME:$PROXY_PASSWORD_ESCAPED"
    else
        echo "Using proxy at $HOST:$PORT without authentication."
    fi

    echo "$SQUID_LINE" > /etc/squid/conf.d/50-parent.conf

fi

exec /usr/local/bin/entrypoint.sh -f /etc/squid/squid.conf -NYC
