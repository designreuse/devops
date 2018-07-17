#!/bin/bash
# -------
# This is standalone script which fix domain configuration for alfresco and camunda
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

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

read -e -p "Please enter the [OLD] public host name for Alfresco server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" OLD_SHARE_HOSTNAME
read -e -p "Please enter the [NEW] public host name for Alfresco server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" SHARE_HOSTNAME
	
if [ -f "$NGINX_CONF/sites-available/$SHARE_HOSTNAME.conf" ]; then
	# Remove old configuration
	rm $NGINX_CONF/sites-available/$SHARE_HOSTNAME.conf
fi

. $BASE_INSTALL/scripts/ssl.sh	$SHARE_HOSTNAME

# Insert cache config
sudo sed -i '1 i\proxy_cache_path \/var\/cache\/nginx\/alfresco levels=1 keys_zone=alfrescocache:256m max_size=512m inactive=1440m;\n' /etc/nginx/sites-available/$SHARE_HOSTNAME.conf

sudo sed -i "0,/server/s/server/upstream alfresco {	\n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n upstream share {    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n&/" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf

sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/share;/g" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf

# Insert alfresco configuration content before the last line in domain.conf in nginx
sudo mkdir temp
sudo cp $NGINX_CONF/sites-available/alfresco.snippet	temp/
sudo sed -e '/##ALFRESCO##/ {' -e 'r temp/alfresco.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
sudo rm -rf temp

sudo mkdir -p /var/cache/nginx/alfresco
  
sudo chown -R www-data:root /var/cache/nginx/alfresco

sudo sed -i "s/$OLD_SHARE_HOSTNAME/$SHARE_HOSTNAME/g"  $CATALINA_HOME/shared/classes/alfresco-global.properties

sudo sed -i "s/$OLD_SHARE_HOSTNAME/$SHARE_HOSTNAME/g"  $CATALINA_HOME/shared/classes/alfresco/web-extension/share-config-custom.xml

sudo sed -i "s/\(^opencmis.context.override=\).*/\1true/"  $CATALINA_HOME/shared/classes/alfresco-global.properties
sudo sed -i "s/\(^opencmis.context.value=\).*/\1/"  $CATALINA_HOME/shared/classes/alfresco-global.properties
sudo sed -i "s/\(^opencmis.servletpath.override=\).*/\1true/"  $CATALINA_HOME/shared/classes/alfresco-global.properties
sudo sed -i "s/\(^opencmis.servletpath.value=\).*/\/"  $CATALINA_HOME/shared/classes/alfresco-global.properties
sudo sed -i "s/\(^opencmis.server.override=\).*/\1true/"  $CATALINA_HOME/shared/classes/alfresco-global.properties
sudo sed -i "s/\(^opencmis.server.value=\).*/\1https:\/\/$SHARE_HOSTNAME/"  $CATALINA_HOME/shared/classes/alfresco-global.properties


read -e -p "Please enter the public host name for Camunda server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" CAMUNDA_HOSTNAME

if [ -f "$NGINX_CONF/sites-available/$CAMUNDA_HOSTNAME.conf" ]; then
	# Remove old configuration
	rm $NGINX_CONF/sites-available/$CAMUNDA_HOSTNAME.conf
fi

# Create a new one to remove common snippet
.	$BASE_INSTALL/scripts/ssl.sh $CAMUNDA_HOSTNAME

  
#echo "Installing configuration for camunda on nginx..."
	
if [ -f "/etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf" ]; then
 sudo sed -i "0,/server/s/server/upstream camunda {    \n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n	upstream engine-rest {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n&/" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
 
 sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/camunda;/g" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
 
 # Insert camunda configuration content before the last line in domain.conf in nginx
 #sudo sed -i "$e cat $NGINX_CONF/sites-available/camunda.conf" /etc/nginx/sites-available/$hostname.conf
 sudo mkdir temp
 sudo cp $NGINX_CONF/sites-available/camunda.snippet	temp/
 sudo sed -e '/##CAMUNDA##/ {' -e 'r temp/camunda.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
 sudo rm -rf temp
fi
