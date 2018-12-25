#!/bin/bash
# -------
# This is script to setup eform workplace
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi

echogreen "Setting up Eforms Camunda..........."

if [ "`which git`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echored "Please run S0.os-upgrade.sh firstly to install git before running this script."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
fi

sudo chmod 775 -R $DEVOPS_HOME
sudo chown -R $USER:$USER ~/.local

if [ -d "$TMP_INSTALL/eformcamundaui" ]; then
	sudo rm -rf $TMP_INSTALL//eformcamundaui
fi

if [ -d "$DEVOPS_HOME/eformsrenderer" ]; then
	sudo rm -rf $DEVOPS_HOME/eformsrenderer
fi

if [ -d "$DEVOPS_HOME/eformsbuilder" ]; then
	sudo rm -rf $DEVOPS_HOME/eformsbuilder
fi


sudo npm install -g grunt-cli
sudo npm install -g @angular/cli
sudo npm install -g bower
sudo npm install -g gulp

# Eform camunda UI
git clone https://bitbucket.org/workplace101/eformscamundaui.git $TMP_INSTALL/eformcamundaui
cd $TMP_INSTALL/eformcamundaui
npm install
grunt
sudo rsync -avz $TMP_INSTALL/eformcamundaui/target/webapp/* 	$CATALINA_HOME/webapps/camunda/

# EForm Renderer
git clone https://bitbucket.org/workplace101/eformsrenderer.git $DEVOPS_HOME/eformsrenderer
cd $DEVOPS_HOME/eformsrenderer
npm install
npm run build

git clone https://bitbucket.org/workplace101/eformsbuilder.git $DEVOPS_HOME/eformsbuilder
cd $DEVOPS_HOME/eformsbuilder
npm install         
bower install       
gulp build
ln -s $DEVOPS_HOME/eformsbuilder/dist $DEVOPS_HOME/eformsrenderer/dist/builder || true

#read -e -p "Please enter the public host name for Eform Renderer (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" EFORM_RENDERER_HOSTNAME
# Check that domain for dev does exist
eforms_line=$(grep "eforms-dev\." $BASE_INSTALL/domain.txt)
if [ -z "$eforms_line" ]; then
	eforms_line=$(grep "eforms\." $BASE_INSTALL/domain.txt)
fi
IFS='|' read -ra arr <<<"$eforms_line"
eforms_hostname="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

read -e -p "Please enter the protocol for Eform server${ques} [http] " -i "http" EFORM_PROTOCOL

if [ "${EFORM_PROTOCOL,,}" = "http" ]; then
	sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$eforms_hostname.conf
else
	sudo rsync -avz $NGINX_CONF/sites-available/domain.conf.ssl /etc/nginx/sites-available/$eforms_hostname.conf
fi

sudo ln -s /etc/nginx/sites-available/$eforms_hostname.conf /etc/nginx/sites-enabled/
sudo sed -i "s/@@DNS_DOMAIN@@/$eforms_hostname/g" /etc/nginx/sites-available/$eforms_hostname.conf

DEVOPS_HOME_PATH="${DEVOPS_HOME//\//\\/}"
sudo sed -i "s/##WEB_ROOT##/root $DEVOPS_HOME_PATH\/eformsrenderer\/dist;/g" /etc/nginx/sites-available/$eforms_hostname.conf

sudo service nginx restart

