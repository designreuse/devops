#!/bin/bash
# -------
# Script for starting/stopping Camunda & Alfresco Tomcat from systemd
#
# -------

export LC_ALL=@@LOCALESUPPORT@@
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export DEVOPS_HOME=/home/devops
export TOMCAT_FOLDER=tomcat
export CATALINA_HOME=$DEVOPS_HOME/$TOMCAT_FOLDER
export CATALINA_BASE=$CATALINA_HOME
export CATALINA_TMPDIR=$CATALINA_HOME/temp
export JRE_HOME=$JAVA_HOME/jre
export PATH=$PATH:$HOME/bin:$JRE_HOME/bin
export CATALINA_PID=$CATALINA_HOME/tomcat.pid

# TODO
# Environment='CATALINA_OPTS=-Xms1024M -Xmx2048M -server -XX:+UseParallelGC'
# Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

# IMPORTANT Update to match memory available on your server.
# For production, A server with at least 8G ram, and -Xmx6G is recommended. More is better!
JAVA_OPTS="-Xms1G -Xmx2G -Xss1024k"
# Below are options that can be used for dealing with memory and garbage collection
# JAVA_OPTS="${JAVA_OPTS} -Xss1024k -XX:MaxPermSize=256m -XX:NewSize=512m -XX:+CMSIncrementalMode -XX:CMSInitiatingOccupancyFraction=80"

# Recommended for Solr4
JAVA_OPTS="${JAVA_OPTS} -XX:+UseConcMarkSweepGC -XX:+UseParNewGC"

JAVA_OPTS="${JAVA_OPTS} -Duser.country=US -Duser.region=US -Duser.language=en -Duser.timezone=\"Asia/Saigon\" -d64"
# Enable this if you encounter problems with transformations of certain pdfs. Side effect is disable of remote debugging
# JAVA_OPTS="${JAVA_OPTS}  -Djava.awt.headless=true"

# Enable if you wish to speed up startup
# Possibly less secure random generation see http://wiki.apache.org/tomcat/HowTo/FasterStartUp#Entropy_Source
JAVA_OPTS="${JAVA_OPTS}  -Djava.security.egd=file:/dev/./urandom"

# set tomcat temp location
JAVA_OPTS="${JAVA_OPTS} -Djava.io.tmpdir=${CATALINA_TMPDIR}"

#File encoding may be correct, but we specify them to be sure
JAVA_OPTS="${JAVA_OPTS} -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
JAVA_OPTS="${JAVA_OPTS} -Dalfresco.home=${DEVOPS_HOME} -Dcom.sun.management.jmxremote=true"
JAVA_OPTS="${JAVA_OPTS} -server"

start(){
    sudo systemctl start devops.service
}

stop(){
    sudo systemctl stop devops.service
}
servicestart() {
    export JAVA_OPTS
    $CATALINA_HOME/bin/startup.sh
}

servicestop(){
    export JAVA_OPTS
    $CATALINA_HOME/bin/shutdown.sh 30 -force 
}

cleanup(){
    SHUTDOWN_PORT=`netstat -vatn|grep LISTEN|grep 8005|wc -l`

    if [ $SHUTDOWN_PORT -ne 0 ]; then
        logger -is -t " (Camunda, Alfresco) Tomcat" "Warning: started, cannot clean tomcat."
    else
        # cleanup temp directory before starting
        {
            sudo rm -rf $CATALINA_TMPDIR/*
        } || {
            logger -i -t " (Camunda, Alfresco) Tomcat" "Warning: Failed to clean tomcat tempdirectory."
        }

        {
            sudo rm -rf $CATALINA_HOME/work/*
        } || {
            logger -i -t " (Camunda, Alfresco) Tomcat" "Warning: Failed to clean tomcat work directory."
        }

        {
            sudo rm -rf $CATALINA_HOME/logs/*
        } || {
            logger -i -t " (Camunda, Alfresco) Tomcat" "Warning: Failed to clean tomcat log directory."
        }
    fi

}
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    servicestart)
        servicestart
        ;;
    servicestop)
        servicestop
        ;;
    cleanup)
        cleanup
        ;;
    restart)
        stop
            sleep 5
        start
        ;;
    status)
        sudo systemctl status devops.service
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|cleanup}"
        exit 1
esac
