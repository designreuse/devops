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

CASHFLOW_HOME=$DEVOPS_HOME/cashflow

echogreen "Setting up Cashflow..........."

if [ "`which git`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echored "Please run ubuntu-upgrade.sh firstly to install git before running this script."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
fi

sudo chmod 775 -R $DEVOPS_HOME
sudo chown -R $USER:$USER ~/.local

if [ -d "$TMP_INSTALL/cashflow" ]; then
	cd $TMP_INSTALL/cashflow
	git pull
else
	git clone https://bitbucket.org/ecashflow/ecashflow.git $TMP_INSTALL/cashflow
fi

cd $TMP_INSTALL/cashflow
mvn clean install

if [ -d "$CATALINA_HOME/webapps/cashflow" ]; then
	sudo rm -rf $CATALINA_HOME/webapps/cashflow*
fi

sudo rsync -avz $TMP_INSTALL/cashflow/cashflow-webapp/target/cashflow*.war $CATALINA_HOME/webapps/cashflow.war

#sudo rsync -avz $BASE_INSTALL/scripts/cashflow.service  /etc/systemd/system/
#sudo systemctl daemon-reload
#sudo systemctl enable cashflow.service
#sudo service cashflow stop
#sudo service cashflow start

read -e -p "Please enter the public host name for your server (only domain name, not subdomain)${ques} [`hostname`] " -i "`hostname`" DOMAIN_NAME
sudo sed -i "s/MYCOMPANY.COM/$DOMAIN_NAME/g" $BASE_INSTALL/domain.txt

cashflow_line=$(grep "eworkflow" $BASE_INSTALL/domain.txt)
IFS='|' read -ra arr <<<"$cashflow_line"
CASHFLOW_HOSTNAME="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
CASHFLOW_PORT="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

read -e -p "Please enter the protocol for Cashflow server (fully qualified domain name)${ques} [http] " -i "http" CASHFLOW_PROTOCOL
  
  if [ "${CASHFLOW_PROTOCOL,,}" = "https" ]; then
	if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
		. $BASE_INSTALL/scripts/ssl.sh	$CASHFLOW_HOSTNAME
	else
		. scripts/ssl.sh $CASHFLOW_HOSTNAME
	fi
  else
	 sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 sudo ln -s /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf /etc/nginx/sites-enabled/
	  
	 sudo sed -i "s/@@DNS_DOMAIN@@/$CASHFLOW_HOSTNAME/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/cashflow;/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
  fi
  
  #echo "Installing configuration for cashflow on nginx..."
	
  if [ -f "/etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf" ]; then
	if [ -n "$CASHFLOW_PORT" ]; then
		TOMCAT_HTTP_PORT=$CASHFLOW_PORT
	fi
	 sudo sed -i "0,/server/s/server/upstream cashflow {    \n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n&/" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 
	 sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/cashflow;/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf

	 sudo mkdir temp
	 sudo cp $NGINX_CONF/sites-available/cashflow.snippet	temp/
	 sudo sed -e '/##CASHFLOW##/ {' -e 'r temp/cashflow.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 sudo rm -rf temp
	 
	 
	CATALINA_HOME_PATH="${CATALINA_HOME//\//\\/}"
	sudo sed -i "s/@@CATALINA_HOME@@/$CATALINA_HOME_PATH/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
		
  fi

sudo service nginx restart

