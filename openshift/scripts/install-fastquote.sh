#!/bin/bash
# -------
# Script to configure and install Cashflow
#
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi

NORMAL_USER=$USER
DOCKER_REGISTRY=172.30.1.1:5000

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

if [ -d "~/fastquote" ]; then
  cd ~/fastquote
  git pull
else
	git clone https://bitbucket.org/insurtech101/fastquote 	~/fastquote
fi

echogreen "..."

# Login with admin, create and configure projects
sudo /usr/local/sbin/oc login -u system:admin
sudo /usr/local/sbin/oc new-project fastquote
sudo /usr/local/sbin/oc adm policy add-role-to-user admin $USER -n fastquote
sudo /usr/local/sbin/oc adm policy add-scc-to-group anyuid system:authenticated
sudo /usr/local/sbin/oc adm policy add-scc-to-user anyuid -z default
sudo /usr/local/sbin/oc process -f $BASE_INSTALL/openshift/scc-config.yml | sudo /usr/local/sbin/oc apply -f -

# Login into openshift with normal user
oc login --server https://localhost:8443 --username $USER --password $USER --insecure-skip-tls-verify

#Login into docker
sudo docker login -u developer -p $(oc whoami -t) $DOCKER_REGISTRY

# Deploy kafka and elasticsearch
#oc process -f kafka.yml | oc apply -f -
#oc process -f elasticsearch.yml | oc apply -f -

# Deploy oracle db
# sudo mkdir /u01
# sudo chown -R $USER:$USER /u01
# sudo chmod -R 755 /u01
# sudo chmod g+s /u01
# sudo docker pull ejlp12/docker-oracle-xe
# sudo docker tag ejlp12/docker-oracle-xe $DOCKER_REGISTRY/fastquote/docker-oracle-xe 
# sudo docker push $DOCKER_REGISTRY/fastquote/docker-oracle-xe
# oc new-app docker-oracle-xe

# Deploy fastquote
## Build project
cd ~/fastquote

## Sometimes, we got some problems into connecting to Oracle Maven Repo
## In that case, Default Maven Repo can be used alternately but we have to download ojdbc driver 
## manually in other sites because it does not exist in Default Maven Repo
mkdir -p ~/.m2/repository/com/oracle/ojdbc8/12.2.0.1
wget http://mvn.sonner.com.br/~maven/com/oracle/ojdbc8/12.2.0.1/ojdbc8-12.2.0.1.jar -P ~/.m2/repository/com/oracle/ojdbc8/12.2.0.1
wget http://mvn.sonner.com.br/~maven/com/oracle/ojdbc8/12.2.0.1/ojdbc8-12.2.0.1.pom -P ~/.m2/repository/com/oracle/ojdbc8/12.2.0.1

# Build project
mvn clean install -Pprod -Dmaven.test.skip=true

if [ -f "~/fastquote/target/fastquote-0.0.1-SNAPSHOT.war" ]; then
	cp target/fastquote-0.0.1-SNAPSHOT.war ~/fastquote/deployment
	~/fastquote/deployment

	# Build and push docker image, create app from image
	sudo docker build -t fastquote -f ./dockerfile_springboot_fastquote .
	sudo docker tag fastquote $DOCKER_REGISTRY/fastquote/fastquote
	sudo docker push $DOCKER_REGISTRY/fastquote/fastquote
	oc new-app fastquote

	# Expose server to external
	read -e -p "Please enter the host name (or public IP) for fastquote [`hostname`] " -i "`hostname`" FQ_HOSTNAME
	oc expose svc/fastquote --hostname=$FQ_HOSTNAME
fi
