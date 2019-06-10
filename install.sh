#!/bin/bash

# Rsyslog script: install.sh
# Rsyslog script description: Build
# Rsyslog build version: 1.0

# *********** check if user is root ***************
if [[ $EUID -ne 0 ]]; then
   echo "[INFO] YOU MUST BE ROOT TO RUN THIS SCRIPT!!!" 
   exit 1
fi

# *********** create logfile ***************
LOGFILE="/var/log/rsyslog-install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** install docker-ce ***************
echo "[INFO] Installing docker-ce..."
tar -xvf ./build/docker-ce.tar > /dev/null 2>&1
rpm -Uivh ./docker-ce/*.rpm > /dev/null 2>&1
rm -rf ./docker-ce
echo "vm.max_map_count=4120294" >> /etc/sysctl.conf
sysctl -q -w vm.max_map_count=4120294
systemctl enable docker > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1
cp ./build/docker-compose /usr/local/bin
echo "[INFO] Docker-ce installed"

# *********** configuring ***************
echo "[INFO] Updating for deployable rsyslog+es..."
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0
sed -i '/#$ModLoad imtcp/c\$ModLoad imtcp' /etc/rsyslog.conf
sed -i '/#$InputTCPServerRun 514/c\$InputTCPServerRun 514' /etc/rsyslog.conf
sed -i 's/#*.* @@remote-host:514/*.* @@172.18.0.3:1514/g' /etc/rsyslog.conf
echo "*.* @@172.18.0.3:1514" > /etc/rsyslog.d/default.conf 
systemctl restart rsyslog > /dev/null 2>&1
firewall-cmd --permanent --zone=public --add-port=514/tcp > /dev/null 2>&1
firewall-cmd --zone=public --permanent --add-masquerade > /dev/null 2>&1
firewall-cmd --zone=public --permanent --add-forward-port=port=9200:proto=tcp:toport=9200:toaddr=172.18.0.2 > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1
echo "[INFO] Update complete"

# *********** load container images module ***************
load_images(){

DIR="."

# *********** extract images ***************
echo "[INFO] Please wait. Extracting images..."
if [ -f $DIR/images/images.tar ]; then
        tar -xvf $DIR/images/images.tar > /dev/null 2>&1
        # rm -f $DIR/images/images.tar
else
        echo "No file to load!"
        exit 0
fi

# *********** load images ***************
echo "[INFO] Loading images..."
for i in elasticsearch.7.1.1 kibana.7.1.1 logstash.7.1.1 nginx.1.16.0; do
        docker load < $DIR/$i.tar
    rm -f ./$i.tar
done
}

# *********** install_rsyslog module ***************
install_rsyslog(){

# ****** building rsyslog ***********
echo "[INFO] Building rsyslog"
docker-compose build >> $LOGFILE 2>&1
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoerror "Could not build Rsyslog via docker-compose (Error Code: $ERROR)."
     echo "get more details in /var/log/rsyslog-install.log locally"
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
echo "[INFO] Obtaining current host IP..."
   host_ip=$(ip route get 1 | awk '{print $NF;exit}')
   echo "[INFO] Rsyslog IP is set to ${host_ip}"

# *********** run modules ***************
load_images
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
