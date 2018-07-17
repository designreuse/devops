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

export CAMUNDA_DB=camunda
export CAMUNDA_USER=camunda

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
    sudo -i -u postgres createdb -O $CAMUNDA_USER $CAMUNDA_DB
    sudo -u postgres psql -d $CAMUNDA_DB -a -f create-schema.sql
fi