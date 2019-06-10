#!/bin/bash

# Rsyslog script: restart.sh
# Rsyslog script description: Build
# Rsyslog build version: 1.0

# Use this script to stop, remove, and restart containers

# *********** check if user is root ***************
if [[ $EUID -ne 0 ]]; then
   echo "[INFO] YOU MUST BE ROOT TO RUN THIS SCRIPT!!!" 
   exit 1
fi

# *********** create logfile ***************
LOGFILE="/var/log/rsyslog-restart.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** destroy containers module ***************
destroy_containers (){

REMOVE="docker ps -a -q"

echo "[INFO] Stopping containers..."
docker-compose stop > /dev/null 2>&1
echo "[INFO] Removing containers..."
docker rm $($REMOVE) > /dev/null 2>&1

}

# *********** install_rsyslog module ***************
install_rsyslog(){

# ****** building rsyslog ***********
echo "[INFO] Building rsyslog"
docker-compose build >> $LOGFILE 2>&1
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoerror "Could not build Rsyslog via docker-compose (Error Code: $ERROR)."
     echo "get more details in /var/log/rsyslog-restart.log locally"
     exit 1
  fi
    
# ****** running rsyslog ***********
echo "[INFO] Running rsyslog"
docker-compose up -d >> $LOGFILE 2>&1
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoerror "Could not run Rsyslog via docker-compose (Error Code: $ERROR)."
     exit 1
  fi
}

# *********** get host ip ***************
#echo "[INFO] Obtaining current host IP..."
   host_ip=$(ip route get 1 | awk '{print $NF;exit}')
#   echo "[INFO] Rsyslog IP is set to ${host_ip}"

# *********** run modules ***************
destroy_containers
install_rsyslog
echo "[INFO] Waiting for containers to start..."
sleep 30
echo "[INFO] Rsyslog prototype is ready"
echo "[INFO] Use the following information to access the rsyslog prototype"
echo " "
echo " "
echo "URL: https://${host_ip}"
echo "USER: syslog"
echo "PASS: syslog"
echo " "
echo " "
