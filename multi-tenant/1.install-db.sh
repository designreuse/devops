#!/bin/bash
# -------
# This is script to setup eform workplace
# -------

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

export TTV_DB=TTV
export TTV_USER=ttv
export TAPAC_DB=TAPAC
export TAPAC_USER=tapac

echogreen "Setting up database for multi tenant..........."

read -e -p "Create TTV Database and user? [y/n] " -i "y" createdbttv
if [ "$createdbttv" = "y" ]; then
  read -s -p "Enter the TTV database password:" TTV_PASSWORD
  echo ""
  read -s -p "Re-Enter the TTV database password:" TTV_PASSWORD2
  if [ "$TTV_PASSWORD" == "$TTV_PASSWORD2" ]; then
    echo "Creating TTV database and user."
    echo "You must supply the root user password for MariaDB:"
    mysql -u root -p << EOF
    #create workforce db
    CREATE DATABASE $TTV_DB DEFAULT CHARACTER SET utf8;
    DROP USER IF EXISTS '$TTV_USER'@'localhost';
    CREATE USER '$TTV_USER'@'localhost' IDENTIFIED BY '$TTV_PASSWORD';
    GRANT ALL PRIVILEGES ON $TTV_DB.* TO '$TTV_USER'@'localhost' WITH GRANT OPTION;
EOF
  echo
  echo "Remember to update server.xml with the TTV database password"
  echo
  else
    echo
    echo "Passwords do not match. Please run the script again for better luck!"
    echo
    exit 1
  fi
fi

read -e -p "Create TAPAC Database and user? [y/n] " -i "y" createdbtapac
if [ "$createdbtapac" = "y" ]; then
  read -s -p "Enter the TAPAC database password:" TAPAC_PASSWORD
  echo ""
  read -s -p "Re-Enter the TAPAC database password:" TAPAC_PASSWORD2
  if [ "$TAPAC_PASSWORD" == "$TAPAC_PASSWORD2" ]; then
    echo "Creating TAPAC database and user."
    echo "You must supply the root user password for MariaDB:"
    mysql -u root -p << EOF
    #create workforce db
    CREATE DATABASE $TAPAC_DB DEFAULT CHARACTER SET utf8;
    DROP USER IF EXISTS '$TAPAC_USER'@'localhost';
    CREATE USER '$TAPAC_USER'@'localhost' IDENTIFIED BY '$TAPAC_PASSWORD';
    GRANT ALL PRIVILEGES ON $TAPAC_DB.* TO '$TAPAC_USER'@'localhost' WITH GRANT OPTION;

    CREATE DATABASE CUSTOM DEFAULT CHARACTER SET utf8;
    USE CUSTOM;
    CREATE TABLE RUNTIME_TENANT (
        ID_ INT AUTO_INCREMENT PRIMARY KEY,
        NAME_ varchar(255)
    );
    CREATE INDEX RUNTIME_TENANT_ID on RUNTIME_TENANT(ID_);
EOF
  echo
  echo "Remember to update server.xml with the TAPAC database password"
  echo
  else
    echo
    echo "Passwords do not match. Please run the script again for better luck!"
    echo
    exit 1
  fi
fi
