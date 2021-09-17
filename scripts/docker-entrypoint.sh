#!/bin/sh
#initiate database according to the default config in blacklist.sql
sqlite3 /etc/sqlite/docker_sqlite_db/blacklist.db < /etc/sqlite/docker_sqlite_db/blacklist.sql
#define cleanup procedure
cleanup() {
  echo "Container stopped, performing cleanup..."
  sqlite3 /etc/sqlite/docker_sqlite_db/blacklist.db .dump > /etc/sqlite/docker_sqlite_db/blacklist.sql
  exit 1
}
#Trap SIGTERM
trap 'cleanup' SIGTERM SIGINT SIGKILL
# maintain this monitor process forever
while sleep 2
do
  wait $!
done