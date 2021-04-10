#!/bin/bash

ss-manager --manager-address /var/run/shadowsocks-manager.sock -c /etc/shadowsocks-libev/conf-vanilla.json
status=$?
if [ $status -ne 0 ]; then
  echo "second process failed! : $status"
  exit $status
fi
