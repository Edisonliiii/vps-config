#############################################Global variables##############################
readonly SS_MONITOR_SCRIPT="[Unit]
Description=SSR monitor

[Service]
ExecStart=/usr/bin/python3 /root/log_monitor.py -tn 100"
readonly SELF_DEFINED_COMMENT="#########"
readonly FUNC_NAME=${FUNCNAME[0]}
readonly BLACKLIST_IMAGE_NAME="edisonleeeee/blacklist_sqlite"
readonly BLACKLIST_SQL_NAME="blacklist.sql"
readonly BLACKLIST_DB_NAME="blacklist.db"

readonly BLACKLIST_SQL_URL="https://www.dropbox.com/s/p41z5f74nej74xf/blacklist.sql"
readonly BLACKLIST_DB_URL="https://www.dropbox.com/s/a3phjz1s2ot49s1/blacklist.db"
readonly LOG_MONITOR_URL="https://www.dropbox.com/s/flcbt4fzmcg8wcw/log_monitor.py"
readonly DOCKER_ENTRYPOINT_URL="https://www.dropbox.com/s/6bu93kcm2c82zts/docker-entrypoint.sh"
readonly SSH_CONFIG_URL="https://www.dropbox.com/s/o27blst30pbncyj/sshd_config"
readonly EPEL_RELEASE="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"

readonly HISTORY_PATH=/etc/profile
readonly SS_MONITOR_PATH=/lib/systemd/system/ss_monitor.service
readonly TARGET_PATH=/etc/sqlite/docker_sqlite_db/
readonly ufw_BIN_PATH=/usr/sbin/
readonly NORMAL_BIN_PATH=/usr/bin/
readonly SSH_CONFIG_PATH=/etc/ssh/sshd_config

# docker container
readonly BLACKLIST_CONTIANER_NAME="edisonleeeee/blacklist_sqlite"

# debug output
readonly STATUS_LINE="[Status]:"

# used to concatenate into a string used as the function name
# key                  -      value
# [Command in shell]   -      [Call name as part of the function name]
declare -A commandN_to_installN=( ["docker"]="docker" \
	                              ["systemctl"]="systemd" \
	                              ["ufw"]="ufw" \
	                              ["passwd"]="passwd" \
	                              ["ssh"]="openssh-server openssh-clients" \
	                              ["chattr"]="e2fsprogs"
	                            )

# waiting for runtime init, global writable
PACKAGE_MANAGER=""                                   # yum or apt
OS_NAME=""                                           # centos/ubuntu
SSH_ACCOUNT_NAME=""
LOGIN_ACCOUNT=""                                     # 所有的edee记得都替换掉
LOGIN_SSH_PATH=""
SSH_KEY_PATH=""

###########################################################################################

###########################################################################################

# Utility Functions
#######################################
# Function formation handler
# Globals:
# Arguments:
#   None
#######################################
function func_prologue(){
  echo "--------------------------------------------"
  echo "FUNCNAME: [$1]"
  echo "Installing command: [$2]"
}

function func_postLogue(){
  echo "--------------------------------------------"
}
###########################################################################################

#######################################
# check OS and config essential variables
# Globals:
#   PACKAGE_MANAGER
#   OS_NAME
# Arguments:
#   None
#######################################
function os_checker(){
  read_os_info="$(grep "^NAME" $"/etc/os-release" | awk -F'"' '{print $2}')"
  if [[ "$read_os_info" == "Ubuntu" ]];
  then
  	# ubuntu
  	echo "[System Info]:$read_os_info"
    PACKAGE_MANAGER="apt"
    OS_NAME="ubuntu"
  else
  	# centos
  	echo "[System Info]:$read_os_info"
    PACKAGE_MANAGER="yum"
    OS_NAME="centos"
  fi
}

#######################################
# docker install on Centos
# Globals:
# Arguments:
#   None
#######################################
function kernel_upgrade_centos(){
  uname -msr                                                                                # show current version
  yum upgrade                                                                               # update packages
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org                                # enable the repo
  rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm                # install the repo
  yum list available --disablerepo='*' --enablerepo=elrepo-kernel                           # listout all kernel available
  yum --enablerepo=elrepo-kernel install kernel-ml                                          # install latest kernel
  # 改写 /etc/default/grub的GRUB_DEFAULT=X -> GRUB_DEFAULT=0  这步要用到sed 需要补上去
  grub2-mkconfig -o /boot/grub2/grub.cfg
}

#######################################
# docker install on Centos
# Globals:
# Arguments:
#   None
#######################################
function install_docker_centos(){
# docker engine installation
  yum remove docker \
             docker-client \
             docker-client-latest \
             docker-common \
             docker-latest \
             docker-latest-logrotate \
             docker-logrotate \
             docker-engine
  yum install -y yum-utils
  yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  yum install docker-ce docker-ce-cli containerd.io
  systemctl start docker
# docker compose installation
  curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}

#######################################
# ufw install on Centos
# Globals:
# Arguments:
#   None
#######################################
function install_ufw_centos(){
  yum install epel-release
  yum install ufw
}

#######################################
# docker install on Ubuntu
# Globals:
# Arguments:
#   None
#######################################
function install_docker_ubuntu(){
# clean the prev installation
  apt-get remove docker docker-engine docker.io containerd runc
# docker engine installation
  apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get install docker-ce docker-ce-cli containerd.io
# docker compose installation
  curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}

#######################################
# Setup ssh account and config the permission
# Globals:
#   LOGIN_ACCOUNT
#   LOGIN_SSH_PATH
#   SSH_KEY_PATH
# Arguments:
#   None
#######################################
function ssh_secure(){
# setup login account
  echo "Creating ssh login hole........"
  echo "Please input the login name you want and save as copy. Reminder: Recommand to setup this name as a password, don't forget to make a copy: "
  read SSH_ACCOUNT_NAME
  adduser -m $SSH_ACCOUNT_NAME                     # add new account for login only
  # init essential paths
  LOGIN_ACCOUNT=/home/$SSH_ACCOUNT_NAME
  LOGIN_SSH_PATH=/home/$SSH_ACCOUNT_NAME/.ssh/
  SSH_KEY_PATH=/home/$SSH_ACCOUNT_NAME/.ssh/authorized_keys
  echo "Setting up pwd........."
  passwd $SSH_ACCOUNT_NAME                      # setup pwd
  gpasswd -a $SSH_ACCOUNT_NAME wheel            # add edee to wheel group
  lid -g wheel                                  # check all sudoers
  echo "Done!"
# /home/edee/.ssh
  if [[ ! -f $LOGIN_SSH_PATH ]]
  then
  	echo "Creating $LOGIN_SSH_PATH......"
    mkdir -p $LOGIN_SSH_PATH
    echo "Done!"
  fi
# /home/edee/.ssh/authorized_keys
  if [[ ! -f "$SSH_KEY_PATH" ]]
  then
  	echo "Creating $SSH_KEY_PATH......."
    touch $SSH_KEY_PATH
    echo "Done!"
  fi
# setup priviledges
#  chmod g-w $LOGIN_ACCOUNT
#  chmod 700 $LOGIN_SSH_PATH
#  chmod 400 $SSH_KEY_PATH
#  chattr +i $SSH_KEY_PATH
#  chattr +i $LOGIN_SSH_PATH

# public key login
# rm -f $SSH_CONFIG_PATH
curl -L $SSH_CONFIG_URL > $SSH_CONFIG_PATH
sed -i "s/\b[LOGINNAME]\b/$SSH_ACCOUNT_NAME/g" "$SSH_CONFIG_PATH"    # has to be double quotes
systemctl restart sshd




# google 2FA check, [coming soon...]

# last step, lock all critical files
#  lsattr /etc/passwd /etc/shadow
#  chattr +i /etc/passwd /etc/shadow
#  lsattr /etc/passwd /etc/shadow

# change history length
# needs to sed /etc/profile and change the number, do it later, [coming soon...]
  source $HISTORY_PATH

# change logout strategy
# needs to sed .bash_logout, and add history -c and clear
}

#######################################
# Initialize the apt/yum and make it ready
# Globals:
#   None
# Arguments:
#   None
#######################################
function package_manager_init(){
  echo "[Updating]..."
  $PACKAGE_MANAGER update
  echo "[Upgrading]..."
  $PACKAGE_MANAGER upgrade
}

#######################################
# Run necessary systemctl application
# Globals:
#   None
# Arguments:
#   systemctl application name
#######################################
function run_systemctl_app(){
  echo "Starting service $1"
  if [[ "$1" == "ufw.service" ]];
  then
    ufw enable
  else
    systemctl start $1
  fi
}

#######################################
# Run blacklist_sqlite image
# Globals:
#   BLACKLIST_IMAGE_NAME
#   PACKAGE_MANAGER
# Arguments:
#   1 -- systemctl (command checked)
#   2 -- systemd   (installation list if not exist)
# eg: if there is no systemctl, then you need to install
#     systemd
#######################################
function check_command_existence(){
  func_prologue ${FUNCNAME[0]} $1
  installer="install_"
  command_name=$1
  command_bin_path=""

  # [TODO] 这部分逻辑必须改掉！
  if [[ $command_name == "ufw" ]];
  then
    command_bin_path="$1_BIN_PATH"             # command_bin_path本身是一个变量名 想让其生效必须${!command_bin_path}
  else
    command_bin_path="NORMAL_BIN_PATH"
  fi
  
  if [ ! command -v $1 &> /dev/null ] || [ ! -f ${!command_bin_path}$1 ];
  then # command doesn't exist
    #shift   # [Caution!] drop one arg
    echo "$1 could not be found"
    echo "Installing command $1..."
    shift
    if ! $PACKAGE_MANAGER install ${commandN_to_installN[$command_name]};
    then
      echo "[Status]: $PACKAGE_MANAGER install error, alter to specific installer!"
      installer+="${commandN_to_installN[$command_name]}"
      installer+="_"
      installer+="$OS_NAME"
      if ! $installer;                                        # here, should never use [[]], or will never literally run it
      then
        echo "[Status]: Installation crapped! Abort!"
        exit 0
      else
        echo "[Status]: Successful!"
      fi
    else
      echo "[Status]: $PACKAGE_MANAGER installing...."
    fi
    echo "[Status]: Done!!!"
  else
    echo "[Status]: $1 already exits! Ready to use!"
  fi
  func_postLogue
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
function make_ss_monitor_systemctl(){
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
  systemctl daemon-reload
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
#   BLACKLIST_IMAGE_NAME
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
function run_blacklist_sqlite_container(){
# check existence of docker image
  if [[ "$(docker images -q $BLACKLIST_IMAGE_NAME 2> /dev/null)" == "" ]];
  then
    echo "Downloading image $BLACKLIST_IMAGE_NAME..."
    docker pull $BLACKLIST_IMAGE_NAME
    echo "Finish downloading the image!"
  fi
# prepare all necessary files
  mkdir -p $TARGET_PATH
  mkdir -p $TARGET_PATH/scripts
  curl -L  $LOG_MONITOR_URL > /root/log_monitor.py
  # install all requirements
  #if [ ! apt install python3-pip ] || [ ! pip3 install pyufw ] || [ ! pip3 install docker ];
  #then
  #  echo "run_blacklist_sqlite_container abort!"
  #  exit 0
  #fi
  if ! $PACKAGE_MANAGER install python3-pip;
  then
    echo "$STATUS_LINE python3-pip install fail! Exit!"
    exit 1
  fi
  pip3 install pyufw
  pip3 install docker
  curl -L $BLACKLIST_SQL_URL > $TARGET_PATH/blacklist.sql
  curl -L $BLACKLIST_DB_URL > $TARGET_PATH/blacklist.db
  curl -L $DOCKER_ENTRYPOINT_URL > $TARGET_PATH/scripts/docker-entrypoint.sh
# check existence of blacklist sql file
  if [ ! -f $TARGET_PATH/blacklist.sql ];
  then
    echo "$STATUS_LINE blacklist.sql not found!"
    exit 1
  fi
# check existence of blacklist db file
  if [ ! -f $TARGET_PATH/blacklist.db ];
  then
    echo "$STATUS_LINE blacklist.db not found!"
    exit 1
  fi
# check existence of docker-entrypoint.sh
  if [ ! -f $TARGET_PATH/scripts/docker-entrypoint.sh ];
  then
    echo "$STATUS_LINE docker-entrypoint.sh not found!"
    exit 1
  fi
# run docker image
  docker run -idt \
             --restart=always \
             --name blacklist_sqlite \
             -v $TARGET_PATH/blacklist.sql:/etc/sqlite/docker_sqlite_db/blacklist.sql \
             -v $TARGET_PATH/blacklist.db:/etc/sqlite/docker_sqlite_db/blacklist.db \
             $BLACKLIST_CONTIANER_NAME
  echo "$STATUS_LINE Blacklist Container is successfully running!"
}

#######################################
# Completly harmless to cleanup docker container [?]
# Globals:
#   $DOCKER_BL_CONTAINER_NAME
# Arguments:
# Necessary Files:
#######################################
function cleanup(){
  docker stop $BLACKLIST_CONTIANER_NAME
  docker rm   $BLACKLIST_CONTIANER_NAME
}

###########################################################################################
#-----------MAIN PART (ubuntu supported currently)
# preparation
os_checker
package_manager_init
# security audition
check_command_existence python3
check_command_existence passwd
check_command_existence ssh
check_command_existence chattr
ssh_secure

# env setup
#echo "Setting up the essential environment ..........."
#echo "|"
#echo "|"
#check_command_existence systemctl systemd
#check_command_existence docker docker.io
#check_command_existence ufw ufw
#run_systemctl_app docker
#make_ss_monitor_systemctl

# run services orchestration
#echo "About to initiate the services ........."
#echo "|"
#echo "|"
#run_blacklist_sqlite_container
#run_systemctl_app ufw.service
#run_systemctl_app ss_monitor.service