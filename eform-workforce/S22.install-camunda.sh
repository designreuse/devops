#!/bin/bash
# -------
# This is standalone script which configure and install Camunda BPM
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

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Camunda BPM."
echo "Download war files and other configuration"
echo "If you have already downloaded your war files you can skip this step and add "
echo "them manually."
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add Camunda war file and configuration${ques} [y/n] " -i "$DEFAULTYESNO" installcamundawar
if [ "$installcamundawar" = "y" ]; then

  # Create temporary folder if not exist
  if [ ! -d "$TMP_INSTALL" ]; then 
    mkdir "$TMP_INSTALL" 
  fi

  echo "Downloading Camunda..."
  curl -# -o $TMP_INSTALL/camunda-bpm-tomcat-$CAMUNDA_VERSION.0.zip $CAMUNDAURL
  echo

  unzip -q $TMP_INSTALL/camunda-bpm-tomcat-*.zip -d $TMP_INSTALL/camunda-bpm-tomcat
  sudo rsync -avz S22.bpm-platform.xml $CATALINA_HOME/conf
  

  # Insert Camunda libs and webapps into tomcat
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/camunda*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/freemarker-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/groovy-all-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/h2-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/java-uuid-generator-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/joda-time-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/mail-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/mybatis-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/slf4j-api-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/slf4j-jdk14-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/webapps/camunda 	$CATALINA_HOME/webapps
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/webapps/engine-rest* 	$CATALINA_HOME/webapps
  
  
	# Get camunda port in domain table
	camunda_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
	IFS='|' read -ra arr <<<"$camunda_line"
	camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	# CAMUNDA_HOSTNAME="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  
	read -e -p "Please enter the public host name for Camunda server (fully qualified domain name): " CAMUNDA_HOSTNAME
	
	if [ -n "$camunda_port" ]; then
		TOMCAT_HTTP_PORT=$camunda_port
	fi
	
  
  # Check if variable TOMCAT_HTTP_PORT is set, if not, we use the default value as 8080
  if [ -z "$TOMCAT_HTTP_PORT" ]; then
	 TOMCAT_HTTP_PORT=8080
  fi
  
  if [ ! -f "/etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf" ]; then
	  read -e -p "Please enter the protocol for Camunda server (fully qualified domain name)${ques} [http] " -i "http" CAMUNDA_PROTOCOL
	  
	  if [ "${CAMUNDA_PROTOCOL,,}" = "https" ]; then
		if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
			. $BASE_INSTALL/scripts/ssl.sh	$CAMUNDA_HOSTNAME
		else
			. scripts/ssl.sh $CAMUNDA_HOSTNAME
		fi
	  else
		 sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
		 sudo ln -s /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf /etc/nginx/sites-enabled/
		  
		 sudo sed -i "s/@@DNS_DOMAIN@@/$CAMUNDA_HOSTNAME/g" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
		 #sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/camunda;/g" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	  fi
  fi
  
  #echo "Installing configuration for camunda on nginx..."
	
  if [ -f "/etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf" ]; then
	# sudo sed -i "0,/server/s/server/upstream camunda {    \n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n	upstream engine-rest {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n&/" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	sudo sed -i "1 i\upstream camunda {    \n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n	upstream engine-rest {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf	 

	 #sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/camunda;/g" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	 
	 # Insert camunda configuration content before the last line in domain.conf in nginx
	 sudo mkdir temp
	 sudo cp $NGINX_CONF/sites-available/camunda.snippet	temp/
	 sudo sed -e '/##CAMUNDA##/ {' -e 'r temp/camunda.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	 sudo rm -rf temp
	 
  fi

  echogreen "Finished installing Camunda BPM"
  echo
else
  echo
  echo "Skipping installing Camunda BPM"
  echo
fi
