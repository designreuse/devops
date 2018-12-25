#!/bin/bash
# -------
# Script to configure and setup Maven, Ant, Tomcat, Database
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

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo


URLERROR=0

for REMOTE in $TOMCAT_DOWNLOAD $JDBCPOSTGRESURL/$JDBCPOSTGRES $JDBCMYSQLURL/$JDBCMYSQL 
do
        wget --spider $REMOTE --no-check-certificate >& /dev/null
        if [ $? != 0 ]
        then
                echored "Please fix this URL: $REMOTE and try again later"
                URLERROR=1
        fi
done

if [ $URLERROR = 1 ]
then
    echo
    echored "Please fix the above errors and rerun."
    echo
    exit
fi

# Create temporary folder for storing downloaded files
if [ ! -d "$TMP_INSTALL" ]; then
  mkdir -p $TMP_INSTALL
fi


##
# MAVEN 3.3.9
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Maven is a build automation tool used primarily for Java projects "
echo "You will also get the option to install this build tool"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install MAVEN build tool${ques} [y/n] " -i "$DEFAULTYESNO" installmaven

if [ "$installmaven" = "y" ]; then
  echogreen "Installing Maven"
  sudo apt-get install maven
  echogreen "Finished installing Maven"
  echo
else
  echo "Skipping install of Maven"
  echo
fi  
  
  
##
# ANT 1.9.13
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "ANT is a tool used for controlling build process "
echo "You will also get the option to install this tool"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install ANT tool${ques} [y/n] " -i "$DEFAULTYESNO" installant

if [ "$installant" = "y" ]; then
  echogreen "Installing Ant"
  sudo apt-get install ant
  echogreen "Finished installing Ant"
  echo  
else
  echo "Skipping install of Ant"
  echo
fi

##
# Tomcat
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Tomcat is a web application server."
echo "You will also get the option to install jdbc lib for Postgresql or MySql/MariaDB."
echo "Install the jdbc lib for the database you intend to use."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Tomcat${ques} [y/n] " -i "$DEFAULTYESNO" installtomcat

if [ "$installtomcat" = "y" ]; then
  echogreen "Installing Tomcat"
  if [ ! -f "$TMP_INSTALL/apache-tomcat-$TOMCAT8_VERSION.tar.gz" ]; then
  echo "Downloading tomcat..."
  curl -# -o $TMP_INSTALL/apache-tomcat-$TOMCAT8_VERSION.tar.gz $TOMCAT_DOWNLOAD
  fi
  # Make sure install dir exists, including logs dir
  sudo mkdir -p $DEVOPS_HOME/logs
  sudo mkdir -p $CATALINA_HOME
  echo "Extracting..."
  tar xf $TMP_INSTALL/apache-tomcat-$TOMCAT8_VERSION.tar.gz -C $TMP_INSTALL
  sudo mv $TMP_INSTALL/apache-tomcat-$TOMCAT8_VERSION $TMP_INSTALL/tomcat
  sudo rm -rf $TMP_INSTALL/tomcat/apache-tomcat-$TOMCAT8_VERSION
  sudo rsync -avz $TMP_INSTALL/tomcat $DEVOPS_HOME
  
  # Remove apps not needed
  sudo rm -rf $CATALINA_HOME/webapps/{docs,examples}
  
  # Change server default port
  sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g" $CATALINA_HOME/conf/server.xml
  sudo sed -i "s/8005/$TOMCAT_SHUTDOWN_PORT/g" $CATALINA_HOME/conf/server.xml
  sudo sed -i "s/8009/$TOMCAT_AJP_PORT/g" $CATALINA_HOME/conf/server.xml

  # Create Tomcat conf folder
  sudo mkdir -p $CATALINA_HOME/conf/Catalina/localhost

  # Download and copy database connector
  echo
  read -e -p "Install Postgres JDBC Connector${ques} [y/n] " -i "$DEFAULTYESNO" installpg
  if [ "$installpg" = "y" ]; then
	curl -# -o $TMP_INSTALL/$JDBCPOSTGRES $JDBCPOSTGRESURL/$JDBCPOSTGRES
	sudo mv $TMP_INSTALL/$JDBCPOSTGRES $CATALINA_HOME/lib
  fi
  
  echo
  read -e -p "Install Mysql JDBC Connector${ques} [y/n] " -i "$DEFAULTYESNO" installmy
  if [ "$installmy" = "y" ]; then
	curl -# -o $TMP_INSTALL/$JDBCMYSQL $JDBCMYSQLURL/$JDBCMYSQL
	sudo mv $TMP_INSTALL/$JDBCMYSQL $CATALINA_HOME/lib
  fi
  echo
  echogreen "Finished installing Tomcat"
  echo

else
  echo "Skipping install of Tomcat"
  echo
fi

# Create devops service
sudo rsync -avz $BASE_INSTALL/tomcat/devops.service /etc/systemd/system/
sudo rsync -avz $BASE_INSTALL/scripts/devops-service.sh $DEVOPS_HOME/
sudo chmod 755 $DEVOPS_HOME/devops-service.sh
sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $DEVOPS_HOME/devops-service.sh

# Change owner of devops home
sudo chown -R $DEVOPS_USER:$DEVOPS_GROUP $DEVOPS_HOME

# Enable the service
sudo systemctl enable devops.service
sudo systemctl daemon-reload
sudo $DEVOPS_HOME/devops-service.sh start

##
# Database
##
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Database"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Please select on of these : [P]osgresql, [MY]sql, [MA]riadb, [Q]uit " -i "$DEFAULTDB" installdb

    case $installdb in
        "P")
      echo "Choosing posgresql..."
      DB_DRIVER=org.postgresql.Driver
      DB_PORT=5432
      DB_SUFFIX=''
      DB_CONNECTOR=postgresql
            . $BASE_INSTALL/scripts/postgresql.sh
            ;;
        "MY")
      echo "Choosing mysql..."
            . $BASE_INSTALL/scripts/mysql.sh
            ;;
        "MA")
      echo "Choosing mariadb..."
            . $BASE_INSTALL/scripts/mariadb.sh
            ;;
    "Q")
      echo "Quitting..."
      ;;
        *) echo invalid option;;
    esac

export DB_SELECTION=$installdb
  




