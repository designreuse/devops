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

if [ -z "$CAMUNDA_PASSWORD" ]; then
   read -s -p "Enter the Camunda database password: " CAMUNDA_PASSWORD
fi

git clone https://bitbucket.org/eworkforce/workflow.git $TMP_INSTALL/workplacebpm

read -e -p "Please enter the public host name for Camunda server (fully qualified domain name): " camunda_hostname

sudo sed -i "s/\(^postgresql.connection.password=\).*/\1$CAMUNDA_PASSWORD/" 	$TMP_INSTALL/workplacebpm/Camunda/MultiTenant-SSO-plugin/src/main/resources/application.properties

cd $TMP_INSTALL/workplacebpm/Camunda/MultiTenant-SSO-plugin
mvn clean install
sudo rsync -avz $TMP_INSTALL/workplacebpm/Camunda/MultiTenant-SSO-plugin/target/workflow-plugin-sso-7.6.1-SNAPSHOT.jar  $CATALINA_HOME/webapps/camunda/WEB-INF/lib/
	
sudo rsync -avz $TMP_INSTALL/workplacebpm/Camunda/DevOps-Environment/web.xml  $CATALINA_HOME/webapps/camunda/WEB-INF/
sudo rsync -avz $TMP_INSTALL/workplacebpm/Camunda/DevOps-Environment/login.html  $CATALINA_HOME/webapps/camunda/app/welcome

sudo sed -i "s/\(^spring.datasource.password=\).*/\1$CAMUNDA_PASSWORD/" 	$TMP_INSTALL/workplacebpm/eForm/gateway/src/main/resources/application.properties

sudo sed -i "s/\(^cashflow.domain=\).*/\1$camunda_hostname/" 	$TMP_INSTALL/workplacebpm/eForm/gateway/src/main/resources/application.properties

cd $TMP_INSTALL/workplacebpm/eForm
mvn clean install
sudo rsync -avz $TMP_INSTALL/workplacebpm/eForm/common/target/common-1.0-SNAPSHOT.jar  $CATALINA_HOME/webapps/camunda/WEB-INF/lib/
sudo rsync -avz $TMP_INSTALL/workplacebpm/eForm/gateway/target/eform.war  $CATALINA_HOME/webapps/
sleep 10

# Remove data of log file tomcat
cat /dev/null > $CATALINA_HOME/logs/catalina.out

sudo $BASE_INSTALL/scripts/devops-service.sh restart

echogreen "Waiting tomcat to deploy eform..........."
while [ "$(grep 'org.apache.catalina.startup.Catalina.start Server startup' $CATALINA_HOME/logs/catalina.out)" == "" ] 
do
  sleep 5
done
echo "Tomcat startup successfully!"

# Check if eform config does exist
eform_found=$(sudo grep -o "eform" /etc/nginx/sites-available/$camunda_hostname.conf | wc -l)

if [ $eform_found = 0 ]; then
	#sudo sed -i "0,/server/s/server/upstream eform {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n&/" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	sudo sed -i "1 i\upstream eform {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n" /etc/nginx/sites-available/$camunda_hostname.conf
		
		# Insert camunda configuration content before the last line in domain.conf in nginx
		#sudo sed -i "$e cat $NGINX_CONF/sites-available/camunda.conf" /etc/nginx/sites-available/$hostname.conf
		sudo mkdir temp
		sudo cp $NGINX_CONF/sites-available/eform.snippet	temp/
		sudo sed -e '/##EFORM##/ {' -e 'r temp/eform.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$camunda_hostname.conf
		sudo rm -rf temp
fi
