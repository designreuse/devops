#!/bin/bash
# -------
# This is script to create user from XLS

# Configure constants
if [ -f "../constants.sh" ]; then
	. ../constants.sh
fi

# Configure colors
if [ -f "../colors.sh" ]; then
	. ../colors.sh
fi

echogreen "Begin running script to create user..........."
echo "Excel file is stored in $TMP_INSTALL/create-user/input"

if [ ! -d "$TMP_INSTALL/create-user/input" ]; then
	mkdir -p $TMP_INSTALL/create-user/input
	echored "There is no input file for this user creation..."
	exit 1
fi

if [ ! -f "$TMP_INSTALL/create-user/input/Create_User_For_Tenant.xls" ]; then
	echored "There is no input file for this user creation..."
	echored "Please put user-creation excel file : Create_User_For_Tenant.xls  into $TMP_INSTALL/create-user/input and run this script again.."
	exit 1
fi

TMP_INSTALL_ESC="${TMP_INSTALL//\//\\/}"
sudo sed -i "s/\(^eform.cli.createUser.filePath=\).*/\1$TMP_INSTALL_ESC\/create-user\/input\/Create_User_For_Tenant.xls/" 	$DEVOPS_HOME/tomcat/webapps/multi-tenant/WEB-INF/classes/application.properties

curl -G localhost:8300/multi-tenant/user/create-user