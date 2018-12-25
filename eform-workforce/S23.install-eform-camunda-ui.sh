#!/bin/bash
# -------
# This is script to setup eform workplace
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
else
	. ../constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
else
	. ../colors.sh	
fi

sudo chmod 775 -R $DEVOPS_HOME
sudo chown -R $USER:$USER ~/.local

echogreen "Setting up Eforms Camunda UI..."

if [ -d "$TMP_INSTALL/eformcamundaui" ]; then
	sudo rm -rf $TMP_INSTALL/eformcamundaui
fi


npm install -g grunt-cli
npm install -g @angular/cli
npm install -g bower
npm install -g gulp

# Eform camunda UI
git clone https://bitbucket.org/workplace101/eformscamundaui.git $TMP_INSTALL/eformcamundaui
cd $TMP_INSTALL/eformcamundaui
npm install
grunt

sudo cp -r $TMP_INSTALL/eformcamundaui/libs/formiojs $TMP_INSTALL/eformcamundaui/target/webapp/app/tasklist/assets/
sudo rsync -avz $TMP_INSTALL/eformcamundaui/target/webapp/* $CATALINA_HOME/webapps/camunda/

echogreen "Set up Eforms Camunda UI completed..."


