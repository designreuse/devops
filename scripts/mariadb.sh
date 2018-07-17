#!/bin/bash
# -------
# Script for install of Mariadb
# -------

export ALFRESCO_DB=alfresco
export ALFRESCO_USER=alfresco
export CAMUNDA_DB=camunda
export CAMUNDA_USER=camunda

echo
echo "--------------------------------------------"
echo "This script will install MariaDB."
echo "and create Devops database and user."
echo "You may first be prompted for sudo password."
echo "When prompted during MariaDB Install,"
echo "type the default root password for MariaDB."
echo "--------------------------------------------"
echo

read -e -p "Install MariaDB? [y/n] " -i "y" installmariadb
if [ "$installmariadb" = "y" ]; then
  sudo apt-get remove --purge *mysql\*
  sudo apt-get autoremove
  sudo apt-get autoclean
  sudo deluser mysql
  sudo rm -rf /var/lib/mysql
  sudo rm -rf /var/log/mysql
  sudo rm -rf /etc/mysql
  sudo apt-get install software-properties-common
  sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
  sudo add-apt-repository "deb [arch=amd64,i386,ppc64el] http://ftp.ddg.lth.se/mariadb/repo/10.1/ubuntu $(lsb_release -cs) main"
  sudo apt-get update
  sudo apt-get install -y mariadb-server
  sudo mysql_secure_installation
  #Tuning database by setting config
  echo "[myisamchk]" | sudo tee -a /etc/mysql/conf.d/mariadb.cnf
  echo "key_buffer_size         = 128M" | sudo tee -a /etc/mysql/conf.d/mariadb.cnf
  
  echo "[mysqld]" | sudo tee -a /etc/mysql/conf.d/mariadb.cnf
  echo "max_allowed_packet      = 128M" | sudo tee -a /etc/mysql/conf.d/mariadb.cnf
  echo "thread_stack            = 1024K"| sudo tee -a /etc/mysql/conf.d/mariadb.cnf
  echo "innodb_log_file_size    = 128M" | sudo tee -a /etc/mysql/conf.d/mariadb.cnf
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
    echo "Creating Alfresco database and user."
    echo "You must supply the root user password for MariaDB:"
    mysql -u root -p << EOF
    #create workforce db
    CREATE DATABASE $ALFRESCO_DB DEFAULT CHARACTER SET utf8;
    DELETE FROM mysql.user WHERE User = '$ALFRESCO_USER';
    CREATE USER '$ALFRESCO_USER'@'localhost' IDENTIFIED BY '$ALFRESCO_PASSWORD';
    GRANT ALL PRIVILEGES ON $ALFRESCO_DB.* TO '$ALFRESCO_USER'@'localhost' WITH GRANT OPTION;
EOF
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
    echo "Creating Camunda database and user."
    echo "You must supply the root user password for MariaDB:"
    mysql -u root -p << EOF
    #create workforce db
    CREATE DATABASE $CAMUNDA_DB DEFAULT CHARACTER SET utf8;
    DELETE FROM mysql.user WHERE User = '$CAMUNDA_USER';
    CREATE USER '$CAMUNDA_USER'@'localhost' IDENTIFIED BY '$CAMUNDA_PASSWORD';
    GRANT ALL PRIVILEGES ON $CAMUNDA_DB.* TO '$CAMUNDA_USER'@'localhost' WITH GRANT OPTION;
EOF
  echo
  echo "Remember to update server.xml with the Camunda database password"
  echo
 
fi
