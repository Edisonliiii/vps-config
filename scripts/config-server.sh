#############################################Global variables##############################
SS_MONITOR_SCRIPT="[Unit]
Description=SSR monitor

[Service]
ExecStart=/usr/bin/python3 /root/log_monitor.py -tn 100"
SS_MONITOR_PATH=/lib/systemd/system/ss_monitor.service
IMAGE_NAME="edisonleeeee/blacklist_sqlite"
###########################################################################################

#####################################init apt##############################################
apt_init(){
  apt update
  apt upgrade
}
###########################################################################################

#####################################check systemctl#######################################
:' $1 -- command name
   $2 -- command
'
check_systemctl_existence(){
  if ! command -v $1 &> /dev/null
  then
      echo "$1 could not be found"
      echo "Installing systemd..."
      apt install $2
      echo "Done"
  fi
}
###########################################################################################

#####################################create ss_monitor#####################################
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
  echo "$SS_MONITOR_SCRIPT" > /lib/systemd/system/ss_monitor.service
  echo "SS_MONITOR has been added to systemctl!"
  echo "Locating at $SS_MONITOR_PATH"
  # run
  systemctl start ss_monitor.service
  systemctl status ss_monitor
}
###########################################################################################

#######################################
# Run blacklist_sqlite image
# Globals:
#   IMAGE_NAME
# Arguments:
#   None
#######################################
run_blacklist_sqlite_contaienr(){
# check existence of docker image
  if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]];
  then
    echo "Downloading image $IMAGE_NAME..."
    docker pull edisonleeeee/blacklist_sqlite
    echo "Finish downloading the image!"
  fi
# check existence of blacklist sql file
# check existence of blacklist db file
# check existence of docker-entrypoint.sh
# run docker image
  docker run -idt --restart=always \
                  --name blacklist_sqlite \
                  -v /root/blacklist.sql:/etc/sqlite/docker_sqlite_db/blacklist.sql \
                  -v /root/blacklist.db:/etc/sqlite/docker_sqlite_db/blacklist.db \
                  869b76e60d2a
}


###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################

apt_init
check_systemctl_existence systemctl systemd
make_ss_monitor_systemctl