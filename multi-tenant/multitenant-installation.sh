#!/bin/bash
# -------
# This is script to install multitenant

# Run script to create databases for multitenant
. 1.install-db.sh

# Run script to configure tomcat for multitenant
. 2.configure-tomcat.sh

# Run script to install eform 
. 3.install-eform.sh