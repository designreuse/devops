#!/bin/bash
# -------
# Script for maintenance shutdown of Alfresco
#
# -------

USER=www-data
DEVOPS_HOME_WWW=/home/devops/www
DOWNTIME=10

#((!$#)) && echo Supply expected downtime in minutes as argument! && exit 1

die () {
    echo >&2 "$@"
    exit 1
}

if [ "$#" -gt 0 ]
  then
   echo $1 | grep -E -q '^[0-9]+$' || die "Numeric argument required, $1 provided"
   DOWNTIME=$1
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Updating maintenance message script file"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo
echo "var downTime = ${DOWNTIME};" | sudo tee  ${DEVOPS_HOME_WWW}/downtime.js
echo "var startTime = `date +%s`;" | sudo tee -a ${DEVOPS_HOME_WWW}/downtime.js
echo "var specialMessage = '$2';" | sudo tee -a ${DEVOPS_HOME_WWW}/downtime.js
sudo chown -R ${USER}:nogroup ${DEVOPS_HOME_WWW}
echo
echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Stopping the Devops tomcat instance"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo
sudo service devops stop
# For 16.04 change to use 
# sudo /home/devops/devops-service.sh stop
