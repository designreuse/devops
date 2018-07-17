#!/bin/bash
# -------
# Script to setup, install and configure all-in-one devops environment
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

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

read -e -p "Please enter the public host name for your server (only domain name, not subdomain)${ques} [`hostname`] " -i "`hostname`" DOMAIN_NAME
sudo sed -i "s/MYCOMPANY.COM/$DOMAIN_NAME/g" $BASE_INSTALL/domain.txt


# Run initializing script for ubuntu
. $BASE_INSTALL/1.ubuntu-upgrade.sh

# Run script to setup Nginx, NVM, PM2, Nodejs, Redis, MongoDB, CertbotSSL, SSL
. $BASE_INSTALL/2.install-MEAN.sh

# Run script to setup Maven, Ant, Java, Tomcat, Database, Jenkins
. $BASE_INSTALL/3.install-TOMCAT.sh

# Run script to setup Alfresco
# TODO for temporary, we need to install Alfresco before Camunda because they use the same server.xml (tomcat)
# but we will find a way to insert alfresco configuration into server.xml instead of overwriting the existing server.xml
. $BASE_INSTALL/4.install-alfresco.sh

# Run script to setup Camunda
. $BASE_INSTALL/5.install-camunda.sh

# Run script to setup Eforms
#. $BASE_INSTALL/6.install-eforms.sh

# Run script to install Magento2
#. $BASE_INSTALL/7.install-magento2.sh

# Run script to install SSL: list of domain & port
. $BASE_INSTALL/8.ssl-domain-port.sh

# Create devops service
sudo rsync -avz $BASE_INSTALL/tomcat/devops.service /etc/systemd/system/
sudo rsync -avz $BASE_INSTALL/scripts/devops-service.sh $DEVOPS_HOME/
sudo chmod 755 $DEVOPS_HOME/devops-service.sh
sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $DEVOPS_HOME/devops-service.sh

# Change owner of devops home
sudo chown -R $DEVOPS_USER:$DEVOPS_GROUP $DEVOPS_HOME

# Enable the service
sudo systemctl enable devops.service
sudo systemctl daemon-reload

sudo $DEVOPS_HOME/devops-service.sh start

echogreen "This is the initial admin password for jenkins : $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"

read -e -p "Do you want to ssh to server remotely by providing username and password${ques} [y/n] " -i "$DEFAULTYESNO" sshremote
if [ "$sshremote" = "y" ]; then
	sudo sed -i "s/\(^PasswordAuthentication \).*/\1yes/" /etc/ssh/sshd_config
	sudo service sshd restart
	sudo usermod --password $(echo PASSWORD | openssl passwd -1 -stdin) $USER
	echogreen "User can ssh to server by using this command : ssh -o PreferredAuthentications=password user@ip"
fi
