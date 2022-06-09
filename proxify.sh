#!/bin/sh

if [ -e /tmp/proxychains4.conf ]; then
  exec proxychains -f /tmp/proxychains4.conf $@
else
  exec $@
fi
