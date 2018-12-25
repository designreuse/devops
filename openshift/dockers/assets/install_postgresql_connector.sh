#!/usr/bin/env sh
set -e

ALF_HOME=/alfresco
VERSION=42.2.4
CONNECTOR=postgresql-$VERSION

cd /tmp
curl -OL http://central.maven.org/maven2/org/postgresql/postgresql/$VERSION/$CONNECTOR.jar

mv $CONNECTOR.jar ${ALF_HOME}/tomcat/lib

rm -rf /tmp/${CONNECTOR}*