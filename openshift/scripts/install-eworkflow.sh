#!/bin/bash
# -------
# Script to configure and install Cashflow
#
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi

NORMAL_USER=$USER
POSTGRESQL_APP_NAME=postgresql

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo


echogreen "If this is the first time you run this script..."
oc login --server https://localhost:8443 --username $USER --password $USER --insecure-skip-tls-verify
oc new-project eworkflow

#Login into docker
sudo docker login -u developer -p $(oc whoami -t) $DOCKER_REGISTRY

# Install postgresql
#sudo docker pull centos/postgresql-96-centos7
#sudo docker tag centos/postgresql-96-centos7 $DOCKER_REGISTRY/eworkflow/postgresql
#sudo docker push $DOCKER_REGISTRY/eworkflow/postgresql
# docker pull registry.access.redhat.com/rhscl/postgresql-96-rhel7
# oc import-image my-rhscl/postgresql-96-rhel7 --from=registry.access.redhat.com/rhscl/postgresql-96-rhel7 --confirm
oc new-app postgresql -e POSTGRESQL_DATABASE=postgres -e POSTGRESQL_PASSWORD=postgres -e POSTGRESQL_USER=postgres

echogreen "Waiting for postgresql container being initialized....."
sleep 20

# export POSTGRESQL_POD=$(oc get pod -l app=postgresql -o jsonpath="{.items[0].metadata.name}")
POSTGRESQL_POD=$(oc get pod -l app=postgresql -o jsonpath="{.items[0].metadata.name}")

##alfresco##
oc exec -i $POSTGRESQL_POD -- bash -c "psql -c \"CREATE USER alfresco WITH PASSWORD 'alfresco';\""
oc exec -i $POSTGRESQL_POD -- bash -c "psql -c 'DROP DATABASE IF EXISTS alfresco;'"
oc exec -i $POSTGRESQL_POD -- bash -c 'createdb -O alfresco alfresco'
oc exec -i $POSTGRESQL_POD -- bash -c 'psql -c "GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;"'

##camunda + eform##
oc exec -i $POSTGRESQL_POD -- bash -c "psql -c \"CREATE USER camunda WITH PASSWORD 'camunda';\""
oc exec -i $POSTGRESQL_POD -- bash -c 'createdb -O camunda camunda'
oc exec -i $POSTGRESQL_POD -- bash -c 'psql -c "GRANT ALL PRIVILEGES ON DATABASE camunda TO camunda;"'

oc rsync sql $POSTGRESQL_POD:/tmp
oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d camunda -a -f /tmp/sql/create-schema.sql'

#sudo docker pull gui81/alfresco:latest
#sudo docker tag gui81/alfresco:latest $DOCKER_REGISTRY/eworkflow/alfresco
## Build custom alfresco docker image
cd $BASE_INSTALL/openshift/dockers
sudo docker build -t alfresco -f ./Dockerfile .
sudo docker tag alfresco $DOCKER_REGISTRY/eworkflow/alfresco
sudo docker push $DOCKER_REGISTRY/eworkflow/alfresco

oc new-app alfresco -e 'DB_KIND=postgresql' -e 'DB_HOST=172.30.86.161' -e 'DB_USERNAME=alfresco' -e 'DB_PASSWORD=alfresco' -e 'DB_NAME=alfresco' -e 'ALFRESCO_PORT=8080'
read -e -p "Please enter the host name (or public IP) for alfresco [`hostname`] " -i "`hostname`" ALF_HOSTNAME

## HTTPS ##
# oc create route edge --service=alfresco \
#    --cert=${KEY_PATH}/alfresco.tctav.com.crt \
#    --key=${KEY_PATH}/alfresco.tctav.com.key \
#    --ca-cert=${KEY_PATH}/alfresco.tctav.com.crt \
#    --hostname=alfresco.tctav.com	--port=8080
##

##HTTP##				
oc expose svc/alfresco --hostname=$ALF_HOSTNAME --port=8080



# git clone https://bitbucket.org/workplace101/workplacebpm     ~/workplacebpm

# # Change configuration
# sudo sed -i "s/\(^spring.datasource.url=\).*/\1jdbc\:postgresql\:\/\/postgresql\:5432\/camunda/"  ~/workplacebpm/src/eForm/gateway/src/main/resources/application.properties
# sudo sed -i "s/\(^spring.datasource.url=\).*/\1jdbc\:postgresql\:\/\/postgresql\:5432\/camunda/"  ~/workplacebpm/src/eForm/gateway/src/main/resources/application.properties
# sudo sed -i "s/\(^spring.datasource.password=\).*/\1camunda/"  ~/workplacebpm/src/eForm/gateway/src/main/resources/application.properties
# cd ~/workplacebpm/src/eForm
# mvn clean install
# cd  ~/workplacebpm/src/workflow-plugin-sso
# sudo sed -i "s/\(^postgresql.connection.url=\).*/\1jdbc\:postgresql\:\/\/postgresql\:5432\/camunda/"  ~/workplacebpm/src/workflow-plugin-sso/src/main/resources/application.properties
# sudo sed -i "s/\(^postgresql.connection.password=\).*/\1camunda/"  ~/workplacebpm/src/workflow-plugin-sso/src/main/resources/application.properties
# mvn clean install

# cp ~/workplacebpm/src/environment/bpm-platform.xml ~/workplacebpm/deployment
# cp ~/workplacebpm/src/environment/server.xml ~/workplacebpm/deployment
# cp ~/workplacebpm/src/environment/web.xml ~/workplacebpm/deployment
# cp ~/workplacebpm/src/environment/login.html ~/workplacebpm/deployment
# cp ~/workplacebpm/src/workflow-plugin-sso/target/workflow-plugin-sso-7.6.1-SNAPSHOT.jar ~/workplacebpm/deployment
# cp ~/workplacebpm/src/eForm/common/target/common-1.0-SNAPSHOT.jar	~/workplacebpm/deployment
# cp ~/workplacebpm/src/eForm/gateway/target/eform.war   ~/workplacebpm/deployment

# sudo docker build -t eform -f ./dockerfile_camunda .
# sudo docker tag eform $DOCKER_REGISTRY/eworkflow/eform
# sudo docker push $DOCKER_REGISTRY/eworkflow/eform
# oc new-app eform
# sleep 20
# echogreen "Waiting for camunda container being initialized....."

# # Create tenant
# # export CAMUNDA_POD=$(oc get pod -l app=eform -o jsonpath="{.items[0].metadata.name}")
# CAMUNDA_POD=$(oc get pod -l app=eform -o jsonpath="{.items[0].metadata.name}")

# oc exec -i $POSTGRESQL_POD -- bash -c "psql -d camunda -a -c \"UPDATE act_ge_property SET value_=2 WHERE name_='historyLevel';\""
# oc exec -i $CAMUNDA_POD -- bash -c 'wget -qO- localhost:8080/eform/tenant/TCI'
# oc exec -i $CAMUNDA_POD -- bash -c 'wget -qO- localhost:8080/eform/tenant/TAPAC?parentTenant=TCI'
# oc exec -i $CAMUNDA_POD -- bash -c 'wget -qO- localhost:8080/eform/tenant/TTV?parentTenant=TAPAC'
					
				

# ##cashflow##
# git clone https://bitbucket.org/ecashflow/ecashflow		~/ecashflow
# cd ~/ecashflow

# #Initialize data#
# oc rsync sql $POSTGRESQL_POD:/tmp

# #Create table for general db and insert data
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -a -f /tmp/sql/update/0.create-user.sql'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -a -f /tmp/sql/update/1.create_cashflow_general_db.sql'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_general -a -c "CREATE SCHEMA IF NOT EXISTS cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_general -a -f /tmp/sql/update/2.cashflow_create_script_general.sql'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_general -a -f /tmp/sql/update/3.insert_data_general.sql'

# #Create table for ttv db and insert data
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -a -f /tmp/sql/update/cashflow_TTV/1.create_cashflow_ttv_db.sql'
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -c "CREATE SCHEMA IF NOT EXISTS cashflow;"'
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -f /tmp/sql/update/cashflow_TTV/2.cashflow_create_script_tenant.sql'
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -f /tmp/sql/update/cashflow_TTV/3.create_function.sql'
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -f /tmp/sql/update/cashflow_TTV/4.insert_system_value.sql'
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -f /tmp/sql/update/cashflow_TTV/5.create_view.sql'
# # oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -f /tmp/sql/update/cashflow_TTV/insert_master_data.sql'

# #Grant permission for cashflow user
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -a -c "GRANT ALL PRIVILEGES ON DATABASE cashflow_general TO cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -a -c "GRANT ALL PRIVILEGES ON DATABASE \"cashflow_TTV\" TO cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -c "GRANT ALL ON SCHEMA cashflow to cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_general -a -c "GRANT ALL ON SCHEMA cashflow to cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cashflow TO cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_general -a -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cashflow TO cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_TTV -a -c "ALTER DEFAULT PRIVILEGES IN SCHEMA cashflow GRANT ALL PRIVILEGES ON TABLES TO cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c 'psql -d cashflow_general -a -c "ALTER DEFAULT PRIVILEGES IN SCHEMA cashflow GRANT ALL PRIVILEGES ON TABLES TO cashflow;"'
# oc exec -i $POSTGRESQL_POD -- bash -c '/tmp/sql/grant-permission.sh'


# # Build and deploy
# sed -i "s/localhost:5432/postgresql:5432/g" ~/ecashflow/cashflow-webapp/src/main/resources/application.properties
# mvn clean install
# cp ~/ecashflow/cashflow-webapp/target/cashflow.jar ~/ecashflow/deployment
# cp -R ~/ecashflow/cashflow-webapp	~/ecashflow/deployment
# cd  ~/ecashflow/deployment
# sudo docker build -t cashflow -f ./Dockerfile_cashflow .
# sudo docker tag cashflow $DOCKER_REGISTRY/eworkflow/cashflow
# sudo docker push $DOCKER_REGISTRY/eworkflow/cashflow
# oc new-app cashflow
# rm -rf ~/ecashflow/deployment/cashflow-webapp

# read -e -p "Please enter the host name (or public IP) for cashflow [`hostname`] " -i "`hostname`" CF_HOSTNAME
# oc expose svc/cashflow --hostname=$CF_HOSTNAME