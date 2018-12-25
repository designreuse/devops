#!/bin/bash
# -------
# This is script to setup cashflow workplace
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

CASHFLOW_HOME=$DEVOPS_HOME/cashflow
mkdir $CASHFLOW_HOME
CASHFLOW_USER=cashflow
CASHFLOW_DB_DEFAULT=cashflow

echogreen "Setting up Cashflow..........."

if [ "`which git`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echored "Please run ubuntu-upgrade.sh firstly to install git before running this script."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
fi

sudo chmod 775 -R $DEVOPS_HOME
#sudo chown -R $USER:$USER ~/.local

if [ -d "$TMP_INSTALL/cashflow" ]; then
	cd $TMP_INSTALL/cashflow
	git pull
else
	git clone https://bitbucket.org/eworkforce/cashflow.git $TMP_INSTALL/cashflow
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
	
#	read -e -p "Do you want to initialize data for Cashflow system ? [y/n] " -i "y" cashflowinitialize
#	if [ "$cashflowinitialize" = "y" ]; then
		
#		if [ -d "$TMP_INSTALL/cashflow" ]; then
#			cd $TMP_INSTALL/cashflow
#			git pull
#		else
#			git clone https://bitbucket.org/ecashflow/ecashflow.git $TMP_INSTALL/cashflow
#		fi
	
		count=`ls -1 $TMP_INSTALL/cashflow/sql/*/*.sql 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			
			sudo -i -u postgres psql -d cashflow_general -c "CREATE SCHEMA IF NOT EXISTS cashflow;"
			sudo -i -u postgres psql -d cashflow_general -a -f  $TMP_INSTALL/cashflow/sql/general/1.create_cashflow_general_db.sql
			sudo -i -u postgres psql -d cashflow_general -a -f  $TMP_INSTALL/cashflow/sql/general/2.cashflow_create_script_general.sql
			sudo -i -u postgres psql -d cashflow_general -a -f  $TMP_INSTALL/cashflow/sql/general/3.insert_data_general.sql
			sudo -i -u postgres psql -d cashflow_general -c "SET SEARCH_PATH TO cashflow; UPDATE tenant SET db_password='"$CASHFLOW_PASSWORD"';"

		else
			echored "Scripts in $TMP_INSTALL/cashflow/sql seems not exist."
		fi
#	fi
	
	sudo -i -u postgres psql -c " GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cashflow TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -c " GRANT ALL PRIVILEGES ON DATABASE cashflow_general TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_general -c "GRANT ALL ON SCHEMA cashflow to $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_general -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cashflow TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_general -c "ALTER DEFAULT PRIVILEGES IN SCHEMA cashflow GRANT ALL PRIVILEGES ON TABLES TO $CASHFLOW_USER;"

	for table in `echo "SELECT schemaname || '.' || relname FROM pg_stat_user_tables;" |  sudo -i -u postgres psql -A -t cashflow_general`;
	do
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;"
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;" | sudo -i -u postgres psql cashflow_general
	done
	
  	echo
	echo "--------------------------------------------"
	echo "This script will create example data for TTV company"
	echo "--------------------------------------------"
	echo

	sudo -u postgres createdb -O $CASHFLOW_USER cashflow_TTV
	#sudo -i -u postgres psql -d cashflow_general -a -f  $TMP_INSTALL/cashflow/sql/3.insert_data_general.sql

	sudo -i -u postgres psql -d cashflow_TTV -c "CREATE SCHEMA IF NOT EXISTS cashflow;"
	sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/tenant_TTV/1.create_cashflow_ttv_db.sql
	sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/tenant_TTV/2.cashflow_create_script_tenant.sql
	sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/tenant_TTV/3.create_function.sql
	sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/tenant_TTV/4.insert_system_value.sql
	sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/tenant_TTV/5.create_view.sql
	sudo -i -u postgres psql -d cashflow_TTV -a -f  $TMP_INSTALL/cashflow/sql/tenant_TTV/insert_master_data.sql

	sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"cashflow_TTV\" TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_TTV -c "GRANT ALL ON SCHEMA cashflow to $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_TTV -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA cashflow TO $CASHFLOW_USER;"
	sudo -i -u postgres psql -d cashflow_TTV -c "ALTER DEFAULT PRIVILEGES IN SCHEMA cashflow GRANT ALL PRIVILEGES ON TABLES TO $CASHFLOW_USER;"

	for table in `echo "SELECT schemaname || '.' || relname FROM pg_stat_user_tables;" |  sudo -i -u postgres psql -A -t cashflow_TTV`;
	do
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;"
		echo "GRANT ALL ON TABLE $table to $CASHFLOW_USER;" | sudo -i -u postgres psql cashflow_TTV
	done

  
fi

camunda_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
IFS='|' read -ra arr <<<"$camunda_line"
camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

cd $TMP_INSTALL/cashflow
mvn clean install

#if [ -d "$CATALINA_HOME/webapps/cashflow" ]; then
#	sudo rm -rf $CATALINA_HOME/webapps/cashflow*
#fi
sudo rsync -avz $TMP_INSTALL/cashflow/cashflow-webapp/* $CASHFLOW_HOME

if [ -f "$TMP_INSTALL/cashflow/cashflow-webapp/target/cashflow.war" ]; then
  sudo cp $DEVOPS_HOME/cashflow/target/cashflow.war $DEVOPS_HOME/tomcat/webapps
  sleep 10
  sudo sed -i "s/\(^spring.datasource.password=\).*/\1$CASHFLOW_PASSWORD/"  $CATALINA_HOME/webapps/cashflow/WEB-INF/classes/application.properties
  sudo sed -i "s/\(^postgresql.default.password=\).*/\1$CASHFLOW_PASSWORD/"  $CATALINA_HOME/webapps/cashflow/WEB-INF/classes/application.properties
  sudo $DEVOPS_HOME/devops-service.sh restart
else
  sudo cp $DEVOPS_HOME/cashflow/target/cashflow.jar $CASHFLOW_HOME
  sudo cp $DEVOPS_HOME/cashflow/src/main/resources/application.properties $CASHFLOW_HOME/

  CASHFLOW_HOME_ESC="${CASHFLOW_HOME//\//\\/}"
  sudo rsync -avz $BASE_INSTALL/scripts/cashflow.service  /etc/systemd/system/
  sudo sed -i "s/@@CASHFLOW_HOME@@/$CASHFLOW_HOME_ESC/g" /etc/systemd/system/cashflow.service
  sudo sed -i "s/\(^spring.datasource.password=\).*/\1$CASHFLOW_PASSWORD/"  $CASHFLOW_HOME/application.properties
  sudo sed -i "s/\(^postgresql.default.password=\).*/\1$CASHFLOW_PASSWORD/"  $CASHFLOW_HOME/application.properties
	sudo sed -i "s/\(^camunda.port=\).*/\1$camunda_port/"  $CASHFLOW_HOME/application.properties

	cashflow_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
	IFS='|' read -ra arr <<<"$cashflow_line"
	CASHFLOW_HOSTNAME="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

	sudo sed -i "s/\(^camunda.domain=\).*/\1$CASHFLOW_HOSTNAME/"  $CASHFLOW_HOME/application.properties


  sudo systemctl daemon-reload
  sudo systemctl enable cashflow.service
  sudo service cashflow stop
  sudo service cashflow start
  CASHFLOW_PORT=8400
fi

if [ -z "$CASHFLOW_PASSWORD" ]; then
	CASHFLOW_PASSWORD=$CASHFLOW_DB_DEFAULT
fi


if [ -z "$CASHFLOW_PORT" ]; then
  CASHFLOW_PORT="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
fi

  
if [ ! -f "/etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf" ]; then
  read -e -p "Please enter the protocol for Cashflow server (fully qualified domain name)${ques} [http] " -i "http" CASHFLOW_PROTOCOL
  
  if [ "${CASHFLOW_PROTOCOL,,}" = "https" ]; then
	if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
		. $BASE_INSTALL/scripts/ssl.sh	$CASHFLOW_HOSTNAME
	else
		. scripts/ssl.sh $CASHFLOW_HOSTNAME
	fi
  else
	 sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 sudo ln -s /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf /etc/nginx/sites-enabled/
	  
	 sudo sed -i "s/@@DNS_DOMAIN@@/$CASHFLOW_HOSTNAME/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	# sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/cashflow;/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
  fi
fi
  
  #echo "Installing configuration for cashflow on nginx..."
  if [ -f "/etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf" ]; then
	if [ -n "$CASHFLOW_PORT" ]; then
		TOMCAT_HTTP_PORT=$CASHFLOW_PORT
	fi
	 #sudo sed -i "0,/server/s/server/upstream cashflow {    \n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n&/" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 sudo sed -i "1 i\upstream cashflow {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 
	 #sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/cashflow;/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf

	 sudo mkdir temp
	 sudo cp $NGINX_CONF/sites-available/cashflow.snippet	temp/
	 sudo sed -e '/##CASHFLOW##/ {' -e 'r temp/cashflow.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
	 sudo rm -rf temp
	 
	 
	CATALINA_HOME_PATH="${CATALINA_HOME//\//\\/}"
	sudo sed -i "s/@@CATALINA_HOME@@/$CATALINA_HOME_PATH/g" /etc/nginx/sites-available/$CASHFLOW_HOSTNAME.conf
		
  fi

sudo service nginx restart
