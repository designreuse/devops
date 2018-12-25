#!/bin/bash
# -------
# This is script which defines constants
# -------

# You have to register an account in redhat https://access.redhat.com/labs/registrationassistant and fill them in REDHAT_USER, REDHAT_PASSWORD variables
export REDHAT_USER=digital@vboss.tech
export REDHAT_PASSWORD=vboss.tech
export JAVA_VERSION=8u181

export MAVEN_URL=http://www-us.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz
export JAVA8URL=http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$JAVA_VERSION_BUILD/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-$JAVA_VERSION

export OPENSHIFT_DIR=/home/ec2-user/openshift
export OPENSHIFT_VERSION=openshift-origin-server-v3.9.0-191fece-linux-64bit
export OPENSHIFT_DATA_DIR=/home/ec2-user/openshift/data
export TMP_INSTALL=/tmp
export OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-server-v3.9.0-191fece-linux-64bit.tar.gz
#export OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v3.10.0/openshift-origin-server-v3.10.0-dd10d17-linux-64bit.tar.gz

## This docker insecure IP Range is needed to configure in docker to which OpenShift Docker Registry can communicate
## We can easily see that IP of docker registry in OpenShift is 172.30.1.1 
export DOCKER_INSECURE_IP_RANGE=172.30.0.0/16
export DOCKER_REGISTRY=172.30.1.1:5000

## Because we want to build FastQuote project at our server which uses Oracle JDBC Connector only accessible from Oracle privately 
# so we also need to register an account at Oracle maven repository maven.oracle.com
export ORACLE_MAVEN_REPO_USERNAME=vbosstech@gmail.com
export ORACLE_MAVEN_REPO_PASSWORD=vboss.tech