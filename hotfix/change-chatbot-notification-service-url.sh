#!/bin/bash
# -------
# This is standalone script which change notification service url
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

export NOTIFICATION_SERVICE_URL=https://scaucwnkwa.execute-api.ap-southeast-1.amazonaws.com/v1/notify/workchat
NOTIFICATION_SERVICE_URL_ESC="${NOTIFICATION_SERVICE_URL//\//\\/}"

sudo sed -i "s/\(^endpoint=\).*/\1$NOTIFICATION_SERVICE_URL_ESC/"       $CATALINA_HOME/webapps/eform/WEB-INF/classes/application.properties

sudo $DEVOPS_HOME/devops-service.sh restart
