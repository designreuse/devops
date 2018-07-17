#!/bin/bash
# -------
# This is script to install eform
# -------	

# Configure constants
if [ -f "../constants.sh" ]; then
	. ../constants.sh
fi

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

if [ -d "$TMP_INSTALL/workplacebpm" ]; then
	sudo rm -rf $TMP_INSTALL/workplacebpm
fi

git clone https://bitbucket.org/workplace101/workplacebpm.git $TMP_INSTALL/workplacebpm


cd $TMP_INSTALL/workplacebpm/src/workflow-plugin-sso
mvn clean install
sudo rsync -avz $TMP_INSTALL/workplacebpm/src/workflow-plugin-sso/target/workflow-plugin-sso-7.6.1-SNAPSHOT.jar  $CATALINA_HOME/webapps/camunda/WEB-INF/lib/
	
sudo rsync -avz $TMP_INSTALL/workplacebpm/src/environment/web.xml  $CATALINA_HOME/webapps/camunda/WEB-INF/
sudo rsync -avz $TMP_INSTALL/workplacebpm/src/environment/login.html  $CATALINA_HOME/webapps/camunda/app/welcome

cd $TMP_INSTALL/workplacebpm/src/eForm
if [ -z "$CAMUNDA_PASSWORD" ]; then
   read -s -p "Enter the Camunda database password: " CAMUNDA_PASSWORD
fi

sudo sed -i "s/\(^spring.datasource.password=\).*/\1$CAMUNDA_PASSWORD/" 	$TMP_INSTALL/workplacebpm/src/eForm/gateway/src/main/resources/application.properties

mvn clean install
sudo rsync -avz $TMP_INSTALL/workplacebpm/src/eForm/common/target/common-1.0-SNAPSHOT.jar  $CATALINA_HOME/webapps/camunda/WEB-INF/lib/
sudo rsync -avz $TMP_INSTALL/workplacebpm/src/eForm/gateway/target/eform.war  $CATALINA_HOME/webapps/
sleep 10

# Remove data of log file tomcat
cat /dev/null > $CATALINA_HOME/logs/catalina.out

sudo $DEVOPS_HOME/devops-service.sh restart

echogreen "Waiting for tomcat to deploy eform..........."
while [ "$(grep 'org.apache.catalina.startup.Catalina.start Server startup' $CATALINA_HOME/logs/catalina.out)" == "" ] 
do
  sleep 5
done
echo "Tomcat startup successfully!"