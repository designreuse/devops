#!/bin/bash
# -------
# This is standalone script which fix port (default is 8080) as TOMCAT_CUSTOM_PORT
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

sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g"  $CATALINA_HOME/shared/classes/alfresco/web-extension/share-config-custom.xml
sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g"  $CATALINA_HOME/shared/classes/alfresco-global.properties

. $DEVOPS_HOME/devops-service.sh restart


