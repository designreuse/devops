#!/bin/bash
# -------
# Script to configure and install Openshift
#
# -------

## First of all, you have to register an account in redhat https://access.redhat.com/labs/registrationassistant/
## and uncomment below two lines: REDHAT_USER=digital@vboss.tech
#REDHAT_USER=#PUT ACCOUNT HERE#
#REDHAT_PASSWORD=#PUT PASSWORD HERE#

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi


if [ ! -d "$OPENSHIFT_DATA_DIR" ]; then
	sudo mkdir -p $OPENSHIFT_DATA_DIR
fi

NORMAL_USER=$USER

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

sudo yum update

##LOCALE##
if [ -f "/etc/profile.d/lang.sh" ]; then
	source /etc/profile.d/lang.sh
fi
cat /dev/null                      | sudo tee --append /etc/locale.conf
echo "export LANG=en_US.UTF-8"     | sudo tee --append	~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" | sudo tee --append	~/.bashrc
echo "export LC_COLLATE=C"         | sudo tee --append	~/.bashrc
echo "export LC_CTYPE=en_US.UTF-8" | sudo tee --append	~/.bashrc
source ~/.bashrc

sudo timedatectl set-timezone Asia/Ho_Chi_Minh 
sudo timedatectl set-ntp yes                    
sudo dd if=/dev/zero of=/swapfile bs=1024 count=16384                  
sudo mkswap /swapfile                                             
sudo chmod 0600 /swapfile                                         
sudo cp /etc/fstab /etc/fstab.bak                                 
echo "/swapfile swap swap defaults 0 0" | sudo tee --append /etc/fstab   
sudo systemctl daemon-reload                                      
sudo swapon /swapfile
echo "search vboss.tech"                | sudo tee --append /etc/resolv.conf  

## Docker and other utilities##
#rhel 6.7
# yum install -y https://get.docker.com/rpm/1.7.0/centos-6/RPMS/x86_64/docker-engine-1.7.0-1.el6.x86_64.rpm
sudo subscription-manager register --username $REDHAT_USER --password $REDHAT_PASSWORD --auto-attach
sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
sudo yum install git zip unzip curl wget nano docker firewalld net-tools bind-utils -y

## Install JAVA ##
##
# Java 8 SDK
##
if [ "`which java`" = "" ]; then
  echoblue "Installing Oracle Java 8. Fetching packages..."
  wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.tar.gz" -P ~/download/

  sudo mkdir /usr/java
  sudo tar xvzf ~/download/jdk-8u181-linux-x64.tar.gz -C /usr/java
  
  #export JAVA_DEST=jdk1.8.0_181
  JAVA_DEST=jdk1.8.0_181
  export JAVA_HOME=/usr/java/$JAVA_DEST/
  sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 1
  sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 1

  echo
  echogreen "Finished installing Oracle Java 8"
  echo
fi

## Install MAVEN ##
wget $MAVEN_URL -P ~/
sudo tar xvf ~/apache-maven-3.5.4-bin.tar.gz -C /usr/local
rm ~/apache-maven-3.5.4-bin.tar.gz
sudo mv /usr/local/apache-maven-* /usr/local/maven
#echo "export M2_HOME=~/maven" | tee --append	~/.bashrc
#echo "export M2=$M2_HOME/bin" | tee --append	~/.bashrc
#echo "export PATH=$M2:$PATH" | tee --append		~/.bashrc
sudo echo '#!/bin/sh'                                | sudo tee /etc/profile.d/maven.sh
sudo echo "export MAVEN_HOME=/usr/local/maven"       | sudo tee /etc/profile.d/maven.sh
sudo echo "export M2_HOME=/usr/local/maven"          | sudo tee /etc/profile.d/maven.sh
sudo echo "export M2=/usr/local/maven/bin"           | sudo tee /etc/profile.d/maven.sh
sudo echo "export PATH=/usr/local/maven/bin:${PATH}" | sudo tee /etc/profile.d/maven.sh

sudo chown -R $USER:$USER /etc/profile.d/maven.sh

sudo chmod a+x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

## Add maven repository configuration
sudo sed -i "/<\/servers>/i \
		<server>	\
    <id>maven.oracle.com<\/id>	\
    <username>$ORACLE_MAVEN_REPO_USERNAME<\/username>	\
    <password>$ORACLE_MAVEN_REPO_PASSWORD<\/password>	\
    <configuration>	\
      <basicAuthScope>	\
        <host>ANY<\/host>	\
        <port>ANY<\/port>	\
        <realm>OAM 11g<\/realm>	\
      <\/basicAuthScope>	\
      <httpConfiguration>	\
        <all>	\
          <params>	\
            <property>	\
              <name>http.protocol.allow-circular-redirects<\/name>	\
              <value>\%b,true<\/value>	\
            <\/property>	\
          <\/params>	\
        <\/all>	\
      <\/httpConfiguration>	\
    <\/configuration>	\
  <\/server> " /usr/local/maven/conf/settings.xml


## Install & Configure firewalld ##
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9200/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5601/tcp --permanent
sudo firewall-cmd --reload

## DOCKER CONFIGURATION ##
# RHEL6  insert this --insecure-registry 172.30.1.1:5000 into /etc/sysconfig/docker
cat /dev/null | sudo tee /etc/docker/daemon.json
echo "{\"insecure-registries\": [\"$DOCKER_INSECURE_IP_RANGE\"]}" | sudo tee --append /etc/docker/daemon.json
# Add ec2-user to docker
# sudo usermod -aG docker ec2-user
sudo systemctl restart docker.service

## OPENSHIFT ORIGIN ##
# OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-server-v3.9.0-191fece-linux-64bit.tar.gz
# TMP_INSTALL=/tmp
wget $OPENSHIFT_URL -P $TMP_INSTALL
tar xvf $TMP_INSTALL/openshift-origin-server-*.tar.gz -C $OPENSHIFT_DIR/
rm -f $TMP_INSTALL/openshift-origin-server-*.tar.gz
echo "export PATH=$PATH:$OPENSHIFT_DIR" | tee --append   ~/.bashrc
source ~/.bashrc

read -e -p "Please enter the public host name or IP for server ${ques} [`hostname`] " -i "`hostname`" ORIGIN_HOSTNAME

#OPENSHIFT_DATA_DIR=/home/ec2-user/openshift/data
#ORIGIN_HOSTNAME=52.65.164.56
# sudo ./oc cluster up --public-hostname=$ORIGIN_HOSTNAME --base-dir=$OPENSHIFT_DATA_DIR
# sudo ./oc cluster up --public-hostname=52.65.164.56 --host-data-dir=/opt/openshift/data
# sudo ./oc cluster up --public-hostname=openshift.vboss.tech --host-data-dir=/opt/openshift/data
# rm -rf ~/.kube
sudo $OPENSHIFT_DIR/$OPENSHIFT_VERSION/oc cluster up --public-hostname=$ORIGIN_HOSTNAME --host-data-dir=$OPENSHIFT_DATA_DIR
sudo $OPENSHIFT_DIR/$OPENSHIFT_VERSION/oc login -u system:admin
sudo $OPENSHIFT_DIR/$OPENSHIFT_VERSION/oc adm policy add-role-to-user system:image-builder $USER
sudo $OPENSHIFT_DIR/$OPENSHIFT_VERSION/oc adm policy add-scc-to-group anyuid system:authenticated
# sudo $OPENSHIFT_DIR/$OPENSHIFT_VERSION/oc adm policy add-scc-to-user anyuid -z default