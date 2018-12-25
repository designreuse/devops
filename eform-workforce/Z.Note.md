
# Step-by-step

- Open port 443

- mkdir /home/ubuntu/devops

- git clone https://github.com/vbosstech/devops-ubuntu.git /home/ubuntu/devops/

- ./devops-installation.sh

- ./S2.install-TOMCAT.sh

- ./S21.install-alfresco.sh

- ./S22.install-camunda.sh

- ./S23.install-eform-camunda-ui.sh (open new session)

- ./S24.8.create-tenant-eform-db.sh

- ./S25.import-users-from-excel.sh

- ./S27.deploy-bpmn-dmn.sh

- ./S28.install-cashflow.sh

# Postgres

- postgresql.conf: listen_addresses='*'

- pg_hba.conf: host all all 0.0.0.0/0 md5

# eCashflow

- sudo cp /tmp/devops-install/workplacebpm/RACE-Excel-BPMN-DMN/fasttrack/RACI-Decision-Making-Criteria.xlsx  /home/devops/eforms/dmn/input/

- sudo cp /tmp/devops-install/workplacebpm/RACE-Excel-BPMN-DMN/fasttrack/bpmn/*.bpmn  /home/devops/eforms/bpmn/

- sudo -i -u postgres psql -d cashflow_TTV -c "select 'ALTER TABLE ' || table_name || ' OWNER TO cashflow;' from information_schema.tables where table_schema = 'cashflow';"

# Restart tomcat

- sudo /home/devops/devops-service.sh restart
