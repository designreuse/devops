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