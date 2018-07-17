#!/bin/bash
# -------
# Script for install of Postgresql
#
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

export ALFRESCO_DB=alfresco
export ALFRESCO_USER=alfresco
export CAMUNDA_DB=camunda
export CAMUNDA_USER=camunda
export CASHFLOW_USER=cashflow
export CASHFLOW_DB=cashflow
export PGADMIN_INSTALLATION_DEST=/home/ubuntu

echo
echo "--------------------------------------------"
echo "This script will install PostgreSQL."
echo "and create Devops database and user."
echo "You may be prompted for sudo password."
echo "--------------------------------------------"
echo

read -e -p "Install PostgreSQL database? [y/n] " -i "y" installpg
if [ "$installpg" = "y" ]; then
  sudo apt-get -y install postgresql postgresql-contrib
  echo
  echo "You will now set the default password for the postgres user."
  echo "This will open a psql terminal, enter:"
  echo
  echo "\\password postgres"
  echo
  echo "and follow instructions for setting postgres admin password."
  echo "Press Ctrl+D or type \\q to quit psql terminal"
  echo "START psql --------"
  DB_PASSWORD=postgres
  sudo -u postgres psql postgres
  echo "END psql --------"
  echo
fi

read -e -p "Create Alfresco Database and user? [y/n] " -i "y" createdbalfresco
if [ "$createdbalfresco" = "y" ]; then
  read -s -p "Enter the Alfresco database password:" ALFRESCO_PASSWORD
  echo ""
  read -s -p "Re-Enter the Alfresco database password:" ALFRESCO_PASSWORD2
 while [ "$ALFRESCO_PASSWORD" != "$ALFRESCO_PASSWORD2" ]; do
		echo "Password does not match. Please try again"
		read -s -p "Enter the Alfresco database password:" ALFRESCO_PASSWORD
		echo ""
		read -s -p "Re-Enter the Alfresco database password:" ALFRESCO_PASSWORD2
  done
    echo
    echo "Creating Alfresco database and user."
	sudo -i -u postgres psql -c "CREATE USER $ALFRESCO_USER WITH PASSWORD '"$ALFRESCO_PASSWORD"';"
	sudo -u postgres createdb -O $ALFRESCO_USER $ALFRESCO_DB
  echo
  echo "Remember to update alfresco-global.properties with the Alfresco database password"
  echo
 
fi

read -e -p "Create Camunda Database and user? [y/n] " -i "y" createdbcamunda
if [ "$createdbcamunda" = "y" ]; then
  read -s -p "Enter the Camunda database password:" CAMUNDA_PASSWORD
  echo ""
  read -s -p "Re-Enter the Camunda database password:" CAMUNDA_PASSWORD2
  while [ "$CAMUNDA_PASSWORD" != "$CAMUNDA_PASSWORD2" ]; do
		echo "Password does not match. Please try again"
		read -s -p "Enter the Camunda database password:" CAMUNDA_PASSWORD
		echo ""
		read -s -p "Re-Enter the Camunda database password:" CAMUNDA_PASSWORD2
  done
    echo
    echo "Creating Camunda database and user."
    sudo -i -u postgres psql -c "CREATE USER $CAMUNDA_USER WITH PASSWORD '"$CAMUNDA_PASSWORD"';"
	sudo -u postgres createdb -O $CAMUNDA_USER $CAMUNDA_DB
  echo
  echo "Remember to update server.xml with the Camunda database password"
  echo
fi

read -e -p "Create Cashflow Database and user? [y/n] " -i "y" createdbcashflow
if [ "$createdbcashflow" = "y" ]; then
  read -s -p "Enter the Cashflow database password:" CASHFLOW_PASSWORD
  echo ""
  read -s -p "Re-Enter the Cashflow database password:" CASHFLOW_PASSWORD2
  while [ "$CASHFLOW_PASSWORD" != "$CASHFLOW_PASSWORD2" ]; do
		echo "Password does not match. Please try again"
		read -s -p "Enter the Cashflow database password:" CASHFLOW_PASSWORD
		echo ""
		read -s -p "Re-Enter the Cashflow database password:" CASHFLOW_PASSWORD2
  done
    echo
    echo "Creating Cashflow database and user."
    sudo -i -u postgres psql -c "CREATE USER $CASHFLOW_USER WITH PASSWORD '"$CASHFLOW_PASSWORD"';"
	sudo -u postgres createdb -O $CASHFLOW_USER cashflow_general
	sudo -u postgres createdb -O $CASHFLOW_USER cashflow_TTV
	sudo -i -u postgres psql -c "CREATE USER $CASHFLOW_USER WITH PASSWORD '"$CASHFLOW_PASSWORD"';"
	
	read -e -p "Do you want to initialize data for Cashflow system ? [y/n] " -i "y" cashflowinitialize
	if [ "$cashflowinitialize" = "y" ]; then
		
		if [ -d "$TMP_INSTALL/cashflow" ]; then
			cd $TMP_INSTALL/cashflow
			git pull
		else
			git clone https://bitbucket.org/ecashflow/ecashflow.git $TMP_INSTALL/cashflow
		fi
	
		count=`ls -1 $TMP_INSTALL/cashflow/sql/*.sql 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			
			sudo -i -u postgres psql -d cashflow_general -c "CREATE SCHEMA IF NOT EXISTS cashflow;"
			sudo -i -u postgres psql -d cashflow_general -a -f  $TMP_INSTALL/cashflow/sql/2.cashflow_create_script_general.sql
			sudo -i -u postgres psql -d cashflow_general -a -f  $TMP_INSTALL/cashflow/sql/3.insert_data_general.sql
			
			sudo -i -u postgres psql -d cashflow_TTV -c "CREATE SCHEMA IF NOT EXISTS cashflow;"
			sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/cashflow_TTV/2.cashflow_create_script_tenant.sql
			sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/cashflow_TTV/3.create_function.sql
			sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/cashflow_TTV/4.insert_system_value.sql
			sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/cashflow_TTV/5.create_view.sql
			
			sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/cashflow_TTV/insert_master_data.sql
			sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/cashflow_TTV/additional_script.sql

		else
			echored "Scripts in $TMP_INSTALL/cashflow/sql seems not exist."
		fi
	fi
	
	sudo -i -u postgres psql -c " GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -c " GRANT ALL PRIVILEGES ON DATABASE cashflow_general TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -c " GRANT ALL PRIVILEGES ON DATABASE \"cashflow_TTV\" TO $CASHFLOW_USER;"
	#sudo -i -u postgres psql -d cashflow_TTV -c "CREATE SCHEMA IF NOT EXISTS cashflow;"
	#sudo -i -u postgres psql -d cashflow_general -c "CREATE SCHEMA IF NOT EXISTS cashflow;"
	sudo -i -u postgres psql -d cashflow_TTV -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cashflow TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_general -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cashflow TO $CASHFLOW_USER;"

	for table in `echo "SELECT schemaname || '.' || relname FROM pg_stat_user_tables;" |  sudo -i -u postgres psql -A -t cashflow_general`;
	do
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;"
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;" | sudo -i -u postgres psql cashflow_general
	done

	for table in `echo "SELECT schemaname || '.' || relname FROM pg_stat_user_tables;" |  sudo -i -u postgres psql -A -t cashflow_TTV`;
	do
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;"
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;" | sudo -i -u postgres psql cashflow_TTV
	done
	
  echo
  echo "Remember to update application properties with the cashflow database info"
  echo
  
fi

read -e -p "Install PostgreSQL Admin (Web)? [y/n] " -i "y" createpgadmin
if [ "$createpgadmin" = "y" ]; then
	 sudo apt-get -y install virtualenv python-pip libpq-dev python-dev
	 cd $PGADMIN_INSTALLATION_DEST
	 virtualenv pgadmin4
	 cd $PGADMIN_INSTALLATION_DEST/pgadmin4
	 source $PGADMIN_INSTALLATION_DEST/pgadmin4/bin/activate
	 curl -# -o $PGADMIN_INSTALLATION_DEST/pgadmin4/pgadmin4-1.6-py2.py3-none-any.whl	https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v1.6/pip/pgadmin4-1.6-py2.py3-none-any.whl
	 pip install $PGADMIN_INSTALLATION_DEST/pgadmin4/pgadmin4-1.6-py2.py3-none-any.whl
	 python $PGADMIN_INSTALLATION_DEST/pgadmin4/lib/python2.7/site-packages/pgadmin4/setup.py
	 deactivate
	 source bin/activate
	 PGADMIN4_HOME=$PGADMIN_INSTALLATION_DEST/pgadmin4
	 PGADMIN4_HOME_ESC="${PGADMIN4_HOME//\//\\/}"
	 sudo rsync -avz $BASE_INSTALL/scripts/pgadmin4.service /etc/systemd/system/
	 sudo sed -i "s/@@PGADMIN4_HOME@@/$PGADMIN4_HOME_ESC/g" /etc/systemd/system/pgadmin4.service
	 sudo systemctl daemon-reload
	 sudo systemctl enable pgadmin4
	 sudo sed -i "1 i\\#\!\/usr\/bin\/env python" $PGADMIN4_HOME/lib/python2.7/site-packages/pgadmin4/pgAdmin4.py
	 sudo chmod a+x	$PGADMIN4_HOME/lib/python2.7/site-packages/pgadmin4/pgAdmin4.py
	 sudo systemctl start pgadmin4
	 sudo ufw allow 5050
	 echogreen "PGAdmin has been installed successfully, you can access via URL : [http/https]://domain_server:5050. "
	 
fi

echo
echo "You must update postgresql configuration to allow password based authentication"
echo "(if you have not already done this)."
echo
echo "Add the following to pg_hba.conf or postgresql.conf (depending on version of postgresql installed)"
echo "located in folder /etc/postgresql/<version>/main/"
echo
echo "host all all 127.0.0.1/32 password"
echo
echo "After you have updated, restart the postgres server: sudo service postgresql restart"
echo
