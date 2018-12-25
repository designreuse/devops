#!/usr/bin/env sh
set -e

# vars
export JAVA_HOME=/usr/java/latest
ALF_HOME=/alfresco
ALF_BIN=alfresco-community-installer-201707-linux-x64.bin
ALF_URL=https://download.alfresco.com/release/community/201707-build-00028/$ALF_BIN
CAMUNDA_URL=https://camunda.org/release/camunda-bpm/tomcat/7.8/camunda-bpm-tomcat-7.8.0.tar.gz

# get alfresco installer
mkdir -p $ALF_HOME
cd /tmp
curl -OL $ALF_URL
chmod +x $ALF_BIN

# install alfresco
./$ALF_BIN --mode unattended --prefix $ALF_HOME --alfresco_admin_password admin

# get rid of installer - makes image smaller
rm $ALF_BIN

# add alfresco user
#useradd alfresco
curl -OL $CAMUNDA_URL
mkdir camunda-bpm-tomcat
tar xvzf camunda-bpm-tomcat-7.8.0.tar.gz -C camunda-bpm-tomcat
#mv bpm-platform.xml ${ALF_HOME}/tomcat/conf

# Insert Camunda libs and webapps into tomcat
mv camunda-bpm-tomcat/server/*/lib/camunda*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/freemarker-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/groovy-all-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/h2-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/java-uuid-generator-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/joda-time-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/mail-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/mybatis-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/slf4j-api-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/lib/slf4j-jdk14-*.jar ${ALF_HOME}/tomcat/lib
mv camunda-bpm-tomcat/server/*/webapps/camunda 	${ALF_HOME}/tomcat/webapps
mv camunda-bpm-tomcat/server/*/webapps/engine-rest* 	${ALF_HOME}/tomcat/webapps

rm -rf camunda-bpm-tomcat*
