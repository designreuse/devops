#!/bin/bash
# -------
# This is script to setup tomcat
# -------

# Configure constants
if [ -f "../constants.sh" ]; then
	. ../constants.sh
fi

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi


sudo sed -i "/<\/GlobalNamingResources>/i \
		<Resource name=\"jdbc\/ttv\"\
				  auth=\"Container\"\
				  type=\"javax.sql.DataSource\"\
				  factory=\"org.apache.tomcat.jdbc.pool.DataSourceFactory\"\
				  uniqueResourceName=\"ttv\"\
				  driverClassName=\"$DB_DRIVER_DEFAULT\"\
				  url=\"jdbc:$DB_CONNECTOR_DEFAULT:\/\/localhost:$DB_PORT_DEFAULT\/$TTV_DB$DB_SUFFIX_DEFAULT\"\
				  username=\"$TTV_USER\"\
				  password=\"$TTV_PASSWORD\"\
				  maxActive=\"20\"\
				  minIdle=\"5\"\/> " $CATALINA_HOME/conf/server.xml      

sudo sed -i "/<\/GlobalNamingResources>/i \
		<Resource name=\"jdbc\/tapac\"\
				  auth=\"Container\"\
				  type=\"javax.sql.DataSource\"\
				  factory=\"org.apache.tomcat.jdbc.pool.DataSourceFactory\"\
				  uniqueResourceName=\"tapac\"\
				  driverClassName=\"$DB_DRIVER_DEFAULT\"\
				  url=\"jdbc:$DB_CONNECTOR_DEFAULT:\/\/localhost:$DB_PORT_DEFAULT\/$TAPAC_DB$DB_SUFFIX_DEFAULT\"\
				  username=\"$TAPAC_USER\"\
				  password=\"$TAPAC_PASSWORD\"\
				  maxActive=\"20\"\
				  minIdle=\"5\"\/> " $CATALINA_HOME/conf/server.xml 

sudo sed -i "/<\/bpm-platform>/i \
	<process-engine name=\"TTV\">\
		<job-acquisition>default</job-acquisition>\
		<datasource>java:jdbc/ttv</datasource>\
		<properties>\
			<property name=\"databaseTablePrefix\">TTV.</property>\
			<property name=\"databaseSchemaUpdate\">true</property>\
			<property name=\"authorizationEnabled\">true</property>\
			<property name=\"jobExecutorDeploymentAware\">true</property>\
		</properties>\
		<plugins>\
			<plugin>\
			<class>org.camunda.bpm.application.impl.event.ProcessApplicationEventListenerPlugin</class>\
			</plugin>\
		</plugins>\
	</process-engine> "	$CATALINA_HOME/conf/bpm-platform.xml 	


sudo sed -i "/<\/bpm-platform>/i \
	<process-engine name=\"TAPAC\">\
		<job-acquisition>default</job-acquisition>\
		<datasource>java:jdbc/tapac</datasource>\
		<properties>\
			<property name=\"databaseTablePrefix\">TAPAC.</property>\
			<property name=\"databaseSchemaUpdate\">true</property>\
			<property name=\"authorizationEnabled\">true</property>\
			<property name=\"jobExecutorDeploymentAware\">true</property>\
		</properties>\
		<plugins>\
			<plugin>\
			<class>org.camunda.bpm.application.impl.event.ProcessApplicationEventListenerPlugin</class>\
			</plugin>\
		</plugins>\
	</process-engine> "	$CATALINA_HOME/conf/bpm-platform.xml 			  				  