#!/bin/bash
# -------
# This is standalone script which configure and install Camunda BPM
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

  sudo unzip -q $TMP_INSTALL/camunda-bpm-tomcat-*.zip -d $TMP_INSTALL/camunda-bpm-tomcat
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/conf/bpm-platform.xml $CATALINA_HOME/conf
  
  
  # Check if camunda config exists in tomcat server.xml
  camunda_found=$(grep -o "camunda" $CATALINA_HOME/conf/server.xml | wc -l)
  
  if [ $camunda_found = 0 ]; then
  
	  # Insert Camunda configuration into server.xml
	  sudo sed -i '/<Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" \/>/s/.*/&\n<Listener className="org.camunda.bpm.container.impl.tomcat.TomcatBpmPlatformBootstrap" \/>/' $CATALINA_HOME/conf/server.xml
	  sudo sed -i '/<\/GlobalNamingResources>/i \
		<Resource name="jdbc\/ProcessEngine"\
				  auth="Container"\
				  type="javax.sql.DataSource"\
				  factory="org.apache.tomcat.jdbc.pool.DataSourceFactory"\
				  uniqueResourceName="process-engine"\
				  driverClassName="@@DB_DRIVER@@"\
				  url="jdbc:@@DB_CONNECTOR@@:\/\/localhost:@@DB_PORT@@\/camunda@@DB_SUFFIX@@"\
				  username="@@DB_USERNAME@@"\
				  password="@@DB_PASSWORD@@"\
				  maxActive="20"\
				  minIdle="5"\/> ' $CATALINA_HOME/conf/server.xml

	  sudo sed -i '/<\/GlobalNamingResources>/i \
		<Resource name="global\/camunda-bpm-platform\/process-engine\/ProcessEngineService\!org.camunda.bpm.ProcessEngineService"\
				  auth="Container"\
				  type="org.camunda.bpm.ProcessEngineService"\
				  description="camunda BPM platform Process Engine Service"\
				  factory="org.camunda.bpm.container.impl.jndi.ProcessEngineServiceObjectFactory" \/> ' $CATALINA_HOME/conf/server.xml				  
	  sudo sed -i '/<\/GlobalNamingResources>/i \
		<Resource name="global/camunda-bpm-platform/process-engine/ProcessApplicationService!org.camunda.bpm.ProcessApplicationService"\
				  auth="Container"\
				  type="org.camunda.bpm.ProcessApplicationService"\
				  description="camunda BPM platform Process Application Service"\
				  factory="org.camunda.bpm.container.impl.jndi.ProcessApplicationServiceObjectFactory"\/> ' $CATALINA_HOME/conf/server.xml
  fi

  # Insert Camunda libs and webapps into tomcat
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/camunda*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/freemarker-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/groovy-all-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/h2-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/java-uuid-generator-*.jar $CATALINA_HOME/lib
  # sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/javax.security.auth.message-api-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/joda-time-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/mail-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/mybatis-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/slf4j-api-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/lib/slf4j-jdk14-*.jar $CATALINA_HOME/lib
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/webapps/camunda 	$CATALINA_HOME/webapps
  #sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/webapps/camunda-welcome 	$CATALINA_HOME/webapps
  sudo rsync -avz $TMP_INSTALL/camunda-bpm-tomcat/server/*/webapps/engine-rest* 	$CATALINA_HOME/webapps
  
  # Replace database configuration, use default value if variable is not set (in case of running this script independently)
  if [ -n "$CAMUNDA_USER" ]; then
	  sudo sed -i "s/@@DB_USERNAME@@/$CAMUNDA_USER/g" $CATALINA_HOME/conf/server.xml  
	  sudo sed -i "s/@@DB_PASSWORD@@/$CAMUNDA_PASSWORD/g" $CATALINA_HOME/conf/server.xml
  else
	  sudo sed -i "s/@@DB_USERNAME@@/$DB_USERNAME_DEFAULT/g" $CATALINA_HOME/conf/server.xml  
	  sudo sed -i "s/@@DB_PASSWORD@@/$DB_PASSWORD_DEFAULT/g" $CATALINA_HOME/conf/server.xml
  fi
  
	if [ $DB_SELECTION = 'MA' ] || [ $DB_SELECTION = 'MY' ] ; then	#mysql
		sudo sed -i "s/@@DB_DRIVER@@/$MYSQL_DB_DRIVER_DEFAULT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/@@DB_PORT@@/$MYSQL_DB_PORT_DEFAULT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/@@DB_CONNECTOR@@/$MYSQL_DB_CONNECTOR_DEFAULT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/@@DB_SUFFIX@@/$MYSQL_DB_SUFFIX_DEFAULT/g" $CATALINA_HOME/conf/server.xml
	else	#postgres
		sudo sed -i "s/@@DB_DRIVER@@/$PG_DB_DRIVER_DEFAULT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/@@DB_PORT@@/$PG_DB_PORT_DEFAULT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/@@DB_CONNECTOR@@/$PG_DB_CONNECTOR_DEFAULT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/@@DB_SUFFIX@@/$PG_DB_SUFFIX_DEFAULT/g" $CATALINA_HOME/conf/server.xml
	fi
	
	if [ -n "$CAMUNDA_DB" ]; then
		sudo sed -i "s/@@DB_NAME@@/$CAMUNDA_DB/g" $CATALINA_HOME/conf/server.xml
	else
		sudo sed -i "s/@@DB_NAME@@/$DB_NAME_DEFAULT/g" $CATALINA_HOME/conf/server.xml
	fi  
   
  
  #if [ "${GLOBAL_PROTOCOL,,}" = "https" ]; then 
	#  sudo rsync -avz $NGINX_CONF/sites-available/camunda.conf.ssl /etc/nginx/sites-available/
	 # mv /etc/nginx/sites-available/camunda.conf.ssl		/etc/nginx/sites-available/camunda.conf
  #else
	#  sudo rsync -avz $NGINX_CONF/sites-available/camunda.conf /etc/nginx/sites-available/
#  fi
 # sudo ln -s /etc/nginx/sites-available/camunda.conf /etc/nginx/sites-enabled/
  
  # Extract domain name from SSL kßey path
  #hostname=$(basename /etc/letsencrypt/live/*/)
  
  # Get camunda port in domain table
	camunda_line=$(grep "camunda" $BASE_INSTALL/domain.txt)
	IFS='|' read -ra arr <<<"$camunda_line"
	camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	CAMUNDA_HOSTNAME="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  
  
    if [ -z "$CAMUNDA_HOSTNAME" ]; then
		read -e -p "Please enter the public host name for Camunda server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" CAMUNDA_HOSTNAME
	fi
	
	if [ -f "$NGINX_CONF/sites-available/$CAMUNDA_HOSTNAME.conf" ] && [ "$CAMUNDA_HOSTNAME" != "$SHARE_HOSTNAME" ]; then
		# Remove old configuration
		rm $NGINX_CONF/sites-available/$CAMUNDA_HOSTNAME.conf
	fi
	
	
	if [ -n "$camunda_port" ]; then
		TOMCAT_HTTP_PORT=$camunda_port
	fi
	
  
  # Check if variable TOMCAT_HTTP_PORT is set, if not, we use the default value as 8080
  if [ -z "$TOMCAT_HTTP_PORT" ]; then
	 TOMCAT_HTTP_PORT=8080
  fi
  
  
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
	 sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/camunda;/g" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
  fi
  
  #echo "Installing configuration for camunda on nginx..."
	
  if [ -f "/etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf" ]; then
	 sudo sed -i "0,/server/s/server/upstream camunda {    \n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n	upstream engine-rest {	    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n&/" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	 
	 sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/camunda;/g" /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	 
	 # Insert camunda configuration content before the last line in domain.conf in nginx
	 #sudo sed -i "$e cat $NGINX_CONF/sites-available/camunda.conf" /etc/nginx/sites-available/$hostname.conf
	 sudo mkdir temp
	 sudo cp $NGINX_CONF/sites-available/camunda.snippet	temp/
	 sudo sed -e '/##CAMUNDA##/ {' -e 'r temp/camunda.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$CAMUNDA_HOSTNAME.conf
	 sudo rm -rf temp
		
  fi
  
  #sudo mkdir -p /var/cache/nginx/camunda
  #sudo chown -R www-data:root /var/cache/nginx/camunda
	
  echogreen "Finished installing Camunda BPM"
  echo
else
  echo
  echo "Skipping installing Camunda BPM"
  echo
fi
