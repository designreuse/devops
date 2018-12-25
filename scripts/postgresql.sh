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

if [ "`which psql`" != "" ]; then
	read -e -p "Uninstall PostgreSQL database? [y/n] " -i "y" uninstallpg
	if [ "$uninstallpg" = "y" ]; then
	  sudo apt-get --purge remove postgresql postgresql-contrib postgresql-common
	  sudo rm -rf /var/lib/postgresql
	  sudo rm -rf /var/log/postgresql
	  sudo rm -rf /etc/postgresql
	fi
fi

read -e -p "Install PostgreSQL database? [y/n] " -i "y" installpg
if [ "$installpg" = "y" ]; then
  sudo apt-get -y install postgresql postgresql-contrib postgresql-common
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


read -e -p "Install PostgreSQL Admin (Web)? [y/n] " -i "y" createpgadmin
if [ "$createpgadmin" = "y" ]; then
	 if [ -d "$PGADMIN_INSTALLATION_DEST/pgadmin4" ]; then
		sudo rm -rf $PGADMIN_INSTALLATION_DEST/pgadmin4
	 fi
	 sudo apt-get -y install virtualenv python-pip libpq-dev python-dev
	 cd $PGADMIN_INSTALLATION_DEST
	 virtualenv pgadmin4
	 cd $PGADMIN_INSTALLATION_DEST/pgadmin4
	 source $PGADMIN_INSTALLATION_DEST/pgadmin4/bin/activate
	 curl -# -o $PGADMIN_INSTALLATION_DEST/pgadmin4/pgadmin4-3.1-py2.py3-none-any.whl	https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v3.1/pip/pgadmin4-3.1-py2.py3-none-any.whl
	 pip install $PGADMIN_INSTALLATION_DEST/pgadmin4/pgadmin4-3.1-py2.py3-none-any.whl
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
