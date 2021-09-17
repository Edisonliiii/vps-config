from functools import reduce
import docker
import re
import pyufw as ufw
import time
import sqlite3
import syslog
import argparse

parser = argparse.ArgumentParser(description='there are some description you can use')
parser.add_argument('-tn','--tailnumber', help='read log from where', required=True)
args = parser.parse_args()

"""
    python3
    pass command via the api of
     docker exec -it [id] [command]
     command = sqlite XXX.db "insert into BANNEDIP (ip_addr) values (IP_ADDR)"
    启动镜像之前必须确保host src目录下存在blacklist.db blacklist.sql
    必须保证镜像名字是blacklist_sqlite
"""

""" [Global Resources]
"""
log_tail_from = args.tailnumber
db_path = "/etc/sqlite/docker_sqlite_db"      ### path in container
db_name = "blacklist_sqlite"                  ### container name (fixed!)
client = docker.from_env()                    ### docker obj
db_container = client.containers.get(db_name) ### db container obj

""" [strategy]
    permanent: permanent_banner
"""
def permanent_banner(ip:str) -> str:
  # ban ip permanently
  insert_cmd = "\"insert into BANNEDIP (ip_addr) values ('{_ip}')\"".format(_ip=ip) # 必须单引号
  sqlite_cmd = "sqlite3 {_db_path}/blacklist.db ".format(_db_path = db_path) + '{_insert_cmd}'.format(_insert_cmd = insert_cmd)
  return sqlite_cmd

def ip_banner():
  """get ip from docker log
     这一版本假定当前host所有的docker都在跑ssr
  """
  """------ read docker containers ------"""
  c_list = client.containers.list(all=False)
  """------------get ip------------------"""
  ip_re = re.compile(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
  token_re = re.compile("failed to handshake with " + r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" + ": authentication error")
  for cur_container in c_list:
    cur_container_log = cur_container.logs(tail=log_tail_from).decode("utf-8")
    for ip in token_re.findall(cur_container_log):
      cur_ip = ip_re.findall(ip)[0]
      # exceptional white-list
      if cur_ip == "127.0.0.1":
        continue
      """ 
          [Ban IP Operation]
          1. system wide ufw update
          2. update database in docker (will auto-backup date when exit or terminated)
      """
      syslog.syslog(syslog.LOG_NOTICE, '[SS-MONITOR]: adding new ip: {_ip} \n'.format(_ip=cur_ip))
      ufw.add("deny from {_ip} to any".format(_ip=cur_ip))
      db_container.exec_run(cmd=permanent_banner(cur_ip), detach=True)

def run():
  while(1):
    syslog.syslog(syslog.LOG_NOTICE, '[SS-MONITOR]: Starting new round ...\n')
    time.sleep(5)
    ip_banner()

if __name__ == '__main__':
  run()
  connection.close()

  