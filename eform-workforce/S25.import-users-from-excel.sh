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

if [ ! -f "$TMP_INSTALL/create-user/input/S25.import_users_to_tenants.xls" ]; then
	echored "There is no input file for this user creation..."
	echored "Please put user-creation excel file : S25.import_users_to_tenants.xls  into $TMP_INSTALL/create-user/input and run this script again.."
	exit 1
fi

camunda_line=$(grep "ecashflow" $BASE_INSTALL/domain.txt)
IFS='|' read -ra arr <<<"$camunda_line"
camunda_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

TMP_INSTALL_ESC="${TMP_INSTALL//\//\\/}"
sudo sed -i "s/\(^eform.cli.createUser.filePath=\).*/\1$TMP_INSTALL_ESC\/create-user\/input\/S25.import_users_to_tenants.xls/" 	$DEVOPS_HOME/tomcat/webapps/eform/WEB-INF/classes/application.properties

curl -G localhost:$camunda_port/eform/user/create-user
