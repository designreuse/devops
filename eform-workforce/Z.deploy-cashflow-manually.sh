cd /tmp/devops-install/cashflow/
git pull
rsync -avz cashflow-webapp/src/  /home/devops/cashflow/src/
mvn clean install
sudo cp cashflow-webapp/target/cashflow.jar /home/devops/cashflow/
sudo service cashflow restart