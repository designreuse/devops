cd /tmp/devops-install/workplacebpm/
git pull
cd eForm/
mvn clean install
sudo rm -rf /home/devops/tomcat/webapps/eform*
sudo cp gateway/target/eform.war /home/devops/tomcat/webapps/
cd /home/devops/tomcat/webapps
sleep 10
sudo cp application.properties eform/WEB-INF/classes/
sudo /home/devops/devops-service.sh restart