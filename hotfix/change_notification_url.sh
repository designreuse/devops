#!/bin/bash
export DEVOPS_HOME=/home/devops
export CATALINA_HOME=$DEVOPS_HOME/tomcat
export NOTIFICATION_SERVICE_URL=https://2ecg1x131e.execute-api.us-east-1.amazonaws.com/devV1/notify/workchat


NOTIFICATION_SERVICE_URL_ESC="${NOTIFICATION_SERVICE_URL//\//\\/}"

sudo sed -i "s/\(^endpoint=\).*/\1$NOTIFICATION_SERVICE_URL_ESC/"  $CATALINA_HOME/webapps/eform/WEB-INF/classes/application.properties


sudo $DEVOPS_HOME/devops-service.sh restart

