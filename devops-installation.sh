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

read -e -p "Please enter the public host name for your server (only domain name, not subdomain): " DOMAIN_NAME
sudo sed -i "s/MYCOMPANY.COM/$DOMAIN_NAME/g" $BASE_INSTALL/domain.txt


##################
# S0. DevOps Environment
##################

# Run initializing script for ubuntu
. $BASE_INSTALL/S0.os-upgrade.sh

# Run script to install Mautic Marketing Automation
# . $BASE_INSTALL/S0.6.install-mautic.sh

# Run script to install Magento2
#. $BASE_INSTALL/S0.7.install-magento2.sh

# Run script to install SSL: list of domain & port
. $BASE_INSTALL/S0.9.ssl-domain-port.sh


##################
# S1. Chatbot Environment
##################

# Run script to setup Nginx, NVM, PM2, Nodejs, Redis, MongoDB, CertbotSSL, SSL
. $BASE_INSTALL/S1.install-MEAN.sh


##################
# S2. eWorkflow & eForms Environment
##################

# Run script to setup Maven, Ant, Java, Tomcat, Database, Jenkins
# . $BASE_INSTALL/S2.install-TOMCAT.sh

# Run script to setup Alfresco
# TODO for temporary, we need to install Alfresco before Camunda because they use the same server.xml (tomcat)
# but we will find a way to insert alfresco configuration into server.xml instead of overwriting the existing server.xml

# . $BASE_INSTALL/S21.install-alfresco.sh
## Run script to setup Camunda

##. $BASE_INSTALL/S22.install-camunda.sh

# Run script to setup Eforms
##. $BASE_INSTALL/S2.3.install-eforms.sh

# Run script to setup Cashflow
##. $BASE_INSTALL/S2.4.install-cashflow.sh


##################
# S9. CLEANUP
##################
### TODO: cleanp `devops` & `temp` folder

# Create devops service

## sudo rsync -avz $BASE_INSTALL/tomcat/devops.service /etc/systemd/system/
## sudo rsync -avz $BASE_INSTALL/scripts/devops-service.sh $DEVOPS_HOME/
## sudo chmod 755 $DEVOPS_HOME/devops-service.sh
## sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $DEVOPS_HOME/devops-service.sh

# Change owner of devops home
# sudo chown -R $DEVOPS_USER:$DEVOPS_GROUP $DEVOPS_HOME

# Enable the DevOps/Tomcat/Workforce Service
## sudo systemctl enable devops.service
## sudo systemctl daemon-reload
## sudo $DEVOPS_HOME/scripts/devops-service.sh start