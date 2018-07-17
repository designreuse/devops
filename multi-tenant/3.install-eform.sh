#!/bin/bash
# -------
# This is script to install eform multitenant
# -------	

# Configure constants
if [ -f "../constants.sh" ]; then
	. ../constants.sh
fi

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

if [ -d "$TMP_INSTALL/workplacebpm-multitenant" ]; then
	sudo rm -rf $TMP_INSTALL/workplacebpm-multitenant
fi

git clone https://bitbucket.org/workplace101/workplacebpm.git $TMP_INSTALL/workplacebpm-multitenant

cd $TMP_INSTALL/workplacebpm-multitenant
git checkout schema-isolation

cd $TMP_INSTALL/workplacebpm-multitenant/src/workflow-plugin-sso
mvn clean install
sudo rsync -avz $TMP_INSTALL/workplacebpm-multitenant/src/workflow-plugin-sso/target/workflow-plugin-sso-7.6.1-SNAPSHOT.jar  $CATALINA_HOME/webapps/camunda/WEB-INF/lib/
	
sudo rsync -avz $TMP_INSTALL/workplacebpm-multitenant/src/environment/web.xml  $CATALINA_HOME/webapps/camunda/WEB-INF/
sudo rsync -avz $TMP_INSTALL/workplacebpm-multitenant/src/environment/login.html  $CATALINA_HOME/webapps/camunda/app/welcome

#cd $TMP_INSTALL/workplacebpm-multitenant/src/eForm
#mvn clean install
#sudo rsync -avz $TMP_INSTALL/workplacebpm-multitenant/src/eForm/common/target/common-1.0-SNAPSHOT.jar  $CATALINA_HOME/webapps/camunda/WEB-INF/lib/
#sudo rsync -avz $TMP_INSTALL/workplacebpm-multitenant/src/eForm/gateway/target/multi-tenant.war  $CATALINA_HOME/webapps/
#sleep 10

# Remove data of log file tomcat
cat /dev/null > $CATALINA_HOME/logs/catalina.out

sudo $DEVOPS_HOME/devops-service.sh restart

echogreen "Waiting for tomcat to deploy multi-tenant..........."
while [ "$(grep 'org.apache.catalina.startup.Catalina.start Server startup' $CATALINA_HOME/logs/catalina.out)" == "" ] 
do
  sleep 5
done
echo "Tomcat startup successfully!"

# Set default user
echo "Creating default user for multi-tenant"
echo "You must supply the root user password for mysql: "
mysql -u root -p < $BASE_INSTALL/multi-tenant/create-user.sql