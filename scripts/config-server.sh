#############################################Global variables##############################
SS_MONITOR_SCRIPT="[Unit]
Description=SSR monitor

[Service]
ExecStart=/usr/bin/python3 /root/log_monitor.py -tn 100"
SS_MONITOR_PATH=/lib/systemd/system/ss_monitor.service
IMAGE_NAME="edisonleeeee/blacklist_sqlite"
CONTIANER_NAME="blacklist_sqlite"
TARGET_PATH="/etc/sqlite/docker_sqlite_db/"
BLACKLIST_SQL_NAME="blacklist.sql"
BLACKLIST_DB_NAME="blacklist.db"
###########################################################################################

#######################################
# Initialize the apt and make it ready
# Globals:
#   None
# Arguments:
#   None
#######################################
apt_init(){
  apt update
  apt upgrade
}

#######################################
# Run necessary systemctl application
# Globals:
#   None
# Arguments:
#   systemctl application name
#######################################
run_systemctl_app(){
  systemctl start $1
}

#######################################
# Run blacklist_sqlite image
# Globals:
#   IMAGE_NAME
# Arguments:
#   1 -- systemctl (command checked)
#   2 -- systemd   (install if not exist)
#######################################
check_command_existence(){
  if ! command -v $1 &> /dev/null
  then
      shift
      echo "$1 could not be found"
      echo "Installing systemd..."
      if ! apt install "$@"
      then
        echo "apt install error, quit!"
        exit 0
      else
        echo "apt installing...."
      fi
      echo "Done!!!"
  fi
}

#######################################
# Make ss_monitor systemctl service &
# run it as well
# Globals:
#   SS_MONITOR_PATH   -- .service path
#   SS_MONITOR_SCRIPT -- .service content
# Arguments:
#   None
#######################################
make_ss_monitor_systemctl(){
  # config
  if [[ -f $SS_MONITOR_PATH ]]
  then
    echo "SS_MONITOR_PATH exits! Will do the writing procedure!"
  else
    echo "Creating service file..."
    touch $SS_MONITOR_PATH
    echo "Finish creating service file!"
  fi
  echo "$SS_MONITOR_SCRIPT" > $SS_MONITOR_PATH
  echo "SS_MONITOR has been added to systemctl!"
  echo "Locating at $SS_MONITOR_PATH"
  # run
  
  # systemctl start ss_monitor.service
  # should fail at this moment
  # systemctl status ss_monitor
}

#######################################
# Run blacklist_sqlite container
# Globals:
#   IMAGE_NAME
# Arguments:
#   None
#   a. path to blacklist.sql
#   b. path to blacklist.db
#   c. path to docker-entrypoint.sh
# Necessary Files:
#   1. blacklist.sql 
#   2. blacklist.db
#   3. scripts/docker-entrypoint.sh
# Notice:
# 当前版本必须在这个bash文件同目录下存在一个docker-entrypoint.sh
# 后续版本中要把这个路径问题解决 从Dockerfile_sqlite统一路径  
#######################################
run_blacklist_sqlite_container(){
# check existence of docker image
  if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]];
  then
    echo "Downloading image $IMAGE_NAME..."
    docker pull $IMAGE_NAME
    echo "Finish downloading the image!"
  fi
# prepare all necessary files
  mkdir -p $TARGET_PATH
  mkdir -p $TARGET_PATH/scripts
  cp ../firewall/log_monitor.py    /root/log_monitor.py
  # install all requirements
  #if [ ! apt install python3-pip ] || [ ! pip3 install pyufw ] || [ ! pip3 install docker ];
  #then
  #  echo "run_blacklist_sqlite_container abort!"
  #  exit 0
  #fi
  apt install python3-pip
  pip3 install pyufw
  pip3 install docker
  cp ../db/docker_db/blacklist.sql $TARGET_PATH/blacklist.sql
  cp ../db/docker_db/blacklist.db  $TARGET_PATH/blacklist.db
  cp ./docker-entrypoint.sh        $TARGET_PATH/scripts/docker-entrypoint.sh
# check existence of blacklist sql file
  if [ ! -f $TARGET_PATH/blacklist.sql ];
  then
    echo "blacklist.sql not found!"
    exit 1
  fi
# check existence of blacklist db file
  if [ ! -f $TARGET_PATH/blacklist.db ];
  then
    echo "blacklist.db not found!"
    exit 1
  fi
# check existence of docker-entrypoint.sh
  if [ ! -f $TARGET_PATH/scripts/docker-entrypoint.sh ];
  then
    echo "docker-entrypoint.sh not found!"
    exit 1
  fi
# run docker image
  docker run -idt \
             --restart=always \
             --name blacklist_sqlite \
             -v $TARGET_PATH/blacklist.sql:/etc/sqlite/docker_sqlite_db/blacklist.sql \
             -v $TARGET_PATH/blacklist.db:/etc/sqlite/docker_sqlite_db/blacklist.db \
             869b76e60d2a
}


#######################################
# Completly harmless to cleanup docker container [?]
# Globals:
#   $CONTAINER_NAME
# Arguments:
# Necessary Files:
#######################################
cleanup(){
  docker stop $CONTIANER_NAME
  docker rm $CONTIANER_NAME
}

###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################

apt_init
check_command_existence systemctl systemd
check_command_existence docker docker.io
check_command_existence ufw ufw
run_systemctl_app docker
make_ss_monitor_systemctl

run_blacklist_sqlite_container
run_systemctl_app ss_monitor.service