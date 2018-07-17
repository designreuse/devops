#!/bin/bash
# -------
# Script for installation of mysql
#
# -------

export ALFRESCO_DB=alfresco
export ALFRESCO_USER=alfresco
export CAMUNDA_DB=camunda
export CAMUNDA_USER=camunda

echo
echo "--------------------------------------------"
echo "This script will install MYSQL-DB."
echo "and create Workforce database and user."
echo "You may first be prompted for sudo password."
echo "When prompted during MYSQL-DB Install,"
echo "type the default root password for MYSQL-DB."
echo "--------------------------------------------"
echo

read -e -p "Install MYSQL-DB? [y/n] " -i "n" installmysqldb
if [ "$installmysqldb" = "y" ]; then
  sudo apt-get install mysql-server
fi

read -e -p "Create Alfresco Database and user? [y/n] " -i "y" createdbalfresco
if [ "$createdbalfresco" = "y" ]; then
  read -s -p "Enter the Alfresco database password:" ALFRESCO_PASSWORD
  echo ""
  read -s -p "Re-Enter the Alfresco database password:" ALFRESCO_PASSWORD2
  if [ "$ALFRESCO_PASSWORD" == "$ALFRESCO_PASSWORD2" ]; then
    echo "Creating Alfresco database and user."
    echo "You must supply the root user password for mysql:"
    mysql -u root -p << EOF
create database $ALFRESCO_DB default character set utf8 collate utf8_bin;
grant all on $ALFRESCO_DB.* to '$ALFRESCO_USER'@'localhost' identified by '$ALFRESCO_PASSWORD' with grant option;
grant all on $ALFRESCO_DB.* to '$ALFRESCO_USER'@'localhost.localdomain' identified by '$ALFRESCO_PASSWORD' with grant option;

EOF
  echo
  echo "Remember to update alfresco-global.properties with the Alfresco database password"
  echo
  else
    echo
    echo "Passwords do not match. Please run the script again for better luck!"
    echo
  fi
fi

read -e -p "Create Camunda Database and user? [y/n] " -i "y" createdbcamunda
if [ "$createdbcamunda" = "y" ]; then
  read -s -p "Enter the Camunda database password:" CAMUNDA_PASSWORD
  echo ""
  read -s -p "Re-Enter the Camunda database password:" CAMUNDA_PASSWORD2
  if [ "$CAMUNDA_PASSWORD" == "$CAMUNDA_PASSWORD2" ]; then
    echo "Creating Camunda database and user."
    echo "You must supply the root user password for mysql:"
    mysql -u root -p << EOF
create database $ALFRESCO_DB default character set utf8 collate utf8_bin;
grant all on $CAMUNDA_DB.* to '$CAMUNDA_USER'@'localhost' identified by '$CAMUNDA_PASSWORD' with grant option;
grant all on $CAMUNDA_DB.* to '$CAMUNDA_USER'@'localhost.localdomain' identified by '$CAMUNDA_PASSWORD' with grant option;

EOF
  echo
  echo "Remember to update server.xml with the Camunda database password"
  echo
  else
    echo
    echo "Passwords do not match. Please run the script again for better luck!"
    echo
  fi
fi
