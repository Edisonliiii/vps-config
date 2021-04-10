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
# Run blacklist_sqlite image
# Globals:
#   IMAGE_NAME
# Arguments:
#   1 -- systemctl (command checked)
#   2 -- systemd   (install if not exist)
#######################################
check_systemctl_existence(){
  if ! command -v $1 &> /dev/null
  then
      echo "$1 could not be found"
      echo "Installing systemd..."
      apt install $2
      echo "Done"
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
  systemctl start ss_monitor.service
  systemctl status ss_monitor
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
#######################################
run_blacklist_sqlite_contaienr(){
# check existence of docker image
  if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]];
  then
    echo "Downloading image $IMAGE_NAME..."
    docker pull $IMAGE_NAME
    echo "Finish downloading the image!"
  fi

mkdir -p $TARGET_PATH
mkdir -p $TARGET_PATH/scripts

cp ../db/docker_db/blacklist.sql $TARGET_PATH/blacklist.sql
cp ../db/docker_db/blacklist.db $TARGET_PATH/blacklist.db
cp ./docker-entrypoint.sh $TARGET_PATH/scripts/docker-entrypoint.sh

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
  if [ ! -f ./docker-entrypoint.sh ];
  then
  	echo "docker-entrypoint.sh not found!"
  	exit 1
  fi
# run docker image
  docker run -idt --restart=always \
                  --name blacklist_sqlite \
                  -v $(pwd)/blacklist.sql:/etc/sqlite/docker_sqlite_db/blacklist.sql \
                  -v $(pwd)/blacklist.db:/etc/sqlite/docker_sqlite_db/blacklist.db \
                  869b76e60d2a
}


###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################

apt_init
check_systemctl_existence systemctl systemd
make_ss_monitor_systemctl
run_blacklist_sqlite_contaienr