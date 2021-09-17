#!/bin/bash

ss-manager --manager-address /var/run/shadowsocks-manager.sock -c /etc/shadowsocks-libev/conf-obfs.json
status=$?
if [ $status -ne 0 ]; then
  echo "first process failed! : $status"
  exit $status
fi