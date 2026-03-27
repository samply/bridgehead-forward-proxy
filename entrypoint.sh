#!/usr/bin/env bash

## All credit to https://stackoverflow.com/questions/6250698/how-to-decode-url-encoded-string-in-shell
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

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

    IP=""
    if [[ $HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IP="$HOST"
      else
        IP="$(getent hosts $HOST | cut -d ' ' -f 1 | tail -1)"
    fi

    if [ ! -z $PROXY_PASSWORD ]; then
        echo "Using proxy at $IP:$PORT with username $PROXY_USERNAME and password (hidden)."
        PROXY_PASSWORD_ESCAPED=$(urldecode "$PROXY_PASSWORD")
        LINE="Upstream http $PROXY_USERNAME:$PROXY_PASSWORD_ESCAPED@$IP:$PORT"
    else
        echo "Using proxy at $IP:$PORT without authentication."
        LINE="Upstream http $IP:$PORT"
    fi

    sed \
      -e 's/^Port .*/Port 3128/' \
      -e 's/^#\?Allow .*/Allow 0.0.0.0\/0/' \
      -e '/^Upstream /d' \
      -e '/^#\?ViaProxyName .*/d' \
      -e "\$a $LINE" \
      -e '$a ViaProxyName "Samply.Bridgehead"' \
      /etc/tinyproxy/tinyproxy.conf > /tmp/tinyproxy.conf
fi

exec /usr/bin/tinyproxy -d -c /tmp/tinyproxy.conf
