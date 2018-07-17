#!/bin/bash
# -------
# Script to configure and setup Maven, Ant, Tomcat, Database
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

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo


URLERROR=0

for REMOTE in $TOMCAT_DOWNLOAD $JDBCPOSTGRESURL/$JDBCPOSTGRES $JDBCMYSQLURL/$JDBCMYSQL \
        $APACHEMAVEN $APACHEANT
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

# # Create home directory for application instance
# if [ ! -d "$DEVOPS_HOME" ]; then
#   mkdir -p $DEVOPS_HOME
# fi

cd $TMP_INSTALL

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
	#DEPRICATED
   echogreen "Installing Maven"
  # echo "Downloading Maven..."
  # curl -# -o $TMP_INSTALL/apache-maven-$MAVEN_VERSION.tar.gz $APACHEMAVEN
  # echo "Extracting..."
  # sudo tar -xf $TMP_INSTALL/apache-maven-$MAVEN_VERSION.tar.gz -C $TMP_INSTALL
  # sudo mv $TMP_INSTALL/apache-maven-$MAVEN_VERSION $TMP_INSTALL/maven
  # sudo mv $TMP_INSTALL/maven $DEVOPS_HOME
  # sudo echo "
# #!/bin/sh
# export MAVEN_HOME=$DEVOPS_HOME/maven
# export M2_HOME=$DEVOPS_HOME/maven
# export M2=$DEVOPS_HOME/maven/bin
# export PATH=$PATH:$DEVOPS_HOME/maven/bin
# " | sudo tee /etc/profile.d/maven.sh

  # sudo chmod a+x /etc/profile.d/maven.sh
  # source /etc/profile.d/maven.sh
  # echo
  
  # sudo apt-get install maven
  # echogreen "Finished installing Maven"
  # echo  
  sudo apt-get install maven
  echogreen "Finished installing Maven"
  echo
else
  echo "Skipping install of Maven"
  echo
fi  
  
  
##
# ANT 1.9.9
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "ANT is a tool used for controlling build process "
echo "You will also get the option to install this tool"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install ANT tool${ques} [y/n] " -i "$DEFAULTYESNO" installant

if [ "$installant" = "y" ]; then
  #DEPRICATED
   echogreen "Installing Ant"
  # echo "Downloading Ant..."
  # curl -# -o $TMP_INSTALL/apache-ant-$ANT_VERSION.tar.gz $APACHEANT
  # echo "Extracting..."
  # sudo tar -xf $TMP_INSTALL/apache-ant-$ANT_VERSION.tar.gz -C $TMP_INSTALL
  # sudo mv $TMP_INSTALL/apache-ant-$ANT_VERSION $TMP_INSTALL/ant
  # sudo mv $TMP_INSTALL/ant $DEVOPS_HOME
  # sudo echo "
# #!/bin/sh
# export ANT_HOME=$DEVOPS_HOME/ant
# export PATH=$PATH:$DEVOPS_HOME/ant/bin
# " | sudo tee /etc/profile.d/ant.sh

  # sudo chmod a+x /etc/profile.d/ant.sh
  # source /etc/profile.d/ant.sh
  # echo
  sudo apt-get install ant
  echogreen "Finished installing Ant"
  echo  
else
  echo "Skipping install of Ant"
  echo
fi

##
# System devops user
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to add a system user that runs the tomcat Devops instance."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add devops system user${ques} [y/n] " -i "$DEFAULTYESNO" adddevops
if [ "$adddevops" = "y" ]; then
  sudo adduser --system --disabled-login --disabled-password --group $DEVOPS_USER
  sudo adduser ubuntu $DEVOPS_USER
  sudo adduser jenkins $DEVOPS_USER
  echo
  echogreen "Finished adding devops user"
  echo
else
  echo "Skipping adding devops user"
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
  sudo rsync -avz $TMP_INSTALL/tomcat $DEVOPS_HOME
  
  # Remove apps not needed
  sudo rm -rf $CATALINA_HOME/webapps/{docs,examples}
  
  # Change server default port
  sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g" $CATALINA_HOME/conf/server.xml
  sudo sed -i "s/8005/$TOMCAT_SHUTDOWN_PORT/g" $CATALINA_HOME/conf/server.xml
  sudo sed -i "s/8009/$TOMCAT_AJP_PORT/g" $CATALINA_HOME/conf/server.xml
  #sudo sed -i "s/443/$TOMCAT_HTTPS_PORT/g"  $CATALINA_HOME/conf/server.xml
  
  # # Change domain tomcat port in nginx config
  # hostname=$(basename /etc/letsencrypt/live/*/)
  # if [ "$hostname" != "" ]; then
  #   sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g" /etc/nginx/sites-available/$hostname.conf
  # fi
  
  # Create Tomcat conf folder
  sudo mkdir -p $CATALINA_HOME/conf/Catalina/localhost

  # Download and copy database connector
  echo
  read -e -p "Install Postgres JDBC Connector${ques} [y/n] " -i "$DEFAULTYESNO" installpg
  if [ "$installpg" = "y" ]; then
  curl -# -O $JDBCPOSTGRESURL/$JDBCPOSTGRES
  sudo mv $JDBCPOSTGRES $CATALINA_HOME/lib
  fi
  echo
  read -e -p "Install Mysql JDBC Connector${ques} [y/n] " -i "$DEFAULTYESNO" installmy
  if [ "$installmy" = "y" ]; then
    cd $TMP_INSTALL
  curl -# -L -O $JDBCMYSQLURL/$JDBCMYSQL
  tar xf $JDBCMYSQL
  cd "$(find . -type d -name "mysql-connector*")"
  sudo mv mysql-connector*.jar $CATALINA_HOME/lib
  fi
  echo
  echogreen "Finished installing Tomcat"
  echo

else
  echo "Skipping install of Tomcat"
  echo
fi

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
  




