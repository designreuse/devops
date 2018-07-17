#!/bin/bash
# -------
# This is standalone script which configure and install magento project
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi

# Global constant
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$DIRNAME/../constants.sh"

if sudo test -f $FILE; then
	. $FILE
fi

MAGENTO_WEB_ROOT_PATH="${MAGENTO_WEB_ROOT//\//\\/}"

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

get_hostname() {
	DOMAIN_NAME=$1
	
	count=1
	while read line || [[ -n "$line" ]]; do
		count=$(expr $count + 1)
		if [ $count -gt 3 ]; then
			IFS='|' read -ra arr <<<"$line"
			domain="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
			port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

			if [[ "$domain" == *"magento"* ]]; then
				# @TODO Better break
				hostname=${domain//MYCOMPANY.COM/$DOMAIN_NAME}
				echo "$hostname"
				exit
			fi

		fi
	done <"$BASE_INSTALL/domain.txt"
}

if [ ! -d "$MAGENTO_WEB_ROOT" ]; then
	echogreen "Please make sure you already have environment installed. If not, please run install-lemp.sh"
	echo "Web root folder : $MAGENTO_WEB_ROOT does not exist. Please create $MAGENTO_WEB_ROOT before running this script."
	exit 1
fi

read -e -p "Please enter the project name${ques} " PROJECT_NAME

if [ -n "$PROJECT_NAME" ]; then
	# Store Magento project for SSL conf
	DIRNAME="$(cd "$(dirname "$0")" && pwd)"
	echo "$PROJECT_NAME" >"$DIRNAME/MAGENTO_PROJECT_NAME"

	# Goto Magento directory
	cd $MAGENTO_WEB_ROOT

	read -e -p "Please enter the Magento version${ques} " -i "$MAGENTO_VERSION_DEFAULT" MAGENTO_VERSION
	sudo composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:$MAGENTO_VERSION $PROJECT_NAME

	# Install database and setup username password based on project name
	#read -e -p "Create Magento Database and user? [y/n] " -i "y" createdbmagento
	#if [ "$createdbmagento" = "y" ]; then
	echo "Installing and configuring magento database and user......"
	read -s -p "Enter the Magento database password:" MAGENTO_PASSWORD
	echo ""
	read -s -p "Re-Enter the Magento database password:" MAGENTO_PASSWORD2
	while [ "$MAGENTO_PASSWORD" != "$MAGENTO_PASSWORD2" ]; do
		echo "Password does not match. Please try again"
		read -s -p "Enter the Magento database password:" MAGENTO_PASSWORD
		echo ""
		read -s -p "Re-Enter the Magento database password:" MAGENTO_PASSWORD2
	done
	#if [ "$MAGENTO_PASSWORD" == "$MAGENTO_PASSWORD2" ]; then
	MAGENTO_DB=$PROJECT_NAME
	MAGENTO_USER=$PROJECT_NAME
	echo "Creating Magento database and user."
	echo "You must supply the root user password for MariaDB:"
	mysql -u root -p <<EOF
	# Drop user and database if exists
	DROP USER IF EXISTS '$MAGENTO_USER'@'localhost';
	DROP DATABASE IF EXISTS $MAGENTO_DB;
	#create magento db
	CREATE DATABASE $MAGENTO_DB DEFAULT CHARACTER SET utf8;
	DELETE FROM mysql.user WHERE User = '$MAGENTO_USER';
	CREATE USER '$MAGENTO_USER'@'localhost' IDENTIFIED BY '$MAGENTO_PASSWORD';
	GRANT ALL PRIVILEGES ON $MAGENTO_DB.* TO '$MAGENTO_USER'@'localhost' WITH GRANT OPTION;
EOF
	echo "Remember to update configuration with the Magento database password"
	read -e -p "Please enter the public host name for your server (only domain name, not subdomain)${ques} [$(hostname)] " -i "$(hostname)" DOMAIN_NAME

	PROTOCOL=https
	HOSTNAME=$(get_hostname "$DOMAIN_NAME")
	echo "$HOSTNAME"

	sudo php $MAGENTO_WEB_ROOT/$PROJECT_NAME/bin/magento setup:install --base-url=$PROTOCOL://$HOSTNAME --backend-frontname=admin --db-host=127.0.0.1 --db-name=$MAGENTO_DB \
		--db-password=$MAGENTO_PASSWORD --db-user=$MAGENTO_USER --admin-firstname=admin --admin-lastname=admin --admin-email=admin@mycompany.com \
		--admin-user=admin --admin-password=$MAGENTO_ADMIN_PASSWORD_DEFAULT --language=en_US --currency=USD --timezone=$TIME_ZONE --use-rewrites=1

	# Set permission on project folder
	cd $MAGENTO_WEB_ROOT/$PROJECT_NAME
	compareVersion=2.2
	var=$(awk 'BEGIN{ print "'$MAGENTO_VERSION'"<"'$compareVersion'" }')
	if [ "$var" -eq 1 ]; then
		sudo find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \;
		sudo find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \;
	else
		sudo find var generated vendor pub/static pub/media app/etc -type f -exec chmod u+w {} \;
		sudo find var vendor generated pub/static pub/media app/etc -type d -exec chmod u+w {} \;
	fi
	sudo chmod u+x bin/magento
	# Permission magento's folder as "www-data:www-data"
	# ":www-data" >>> "root:www-data"
	sudo chown -R www-data:www-data .
else
	echo "Please input valid name for creating project"
fi

echo
echogreen "- - - - - - - - - - - - - - - - -"
echo "Scripted install complete"
echo
echored "Magento has been installed with following database info : "
echored " DB Name : $MAGENTO_DB"
echored " DB Username : $MAGENTO_USER"
echored " DB Password : $MAGENTO_PASSWORD"
echo
echo "Magento web app can be accessed via URL : "
echored " $PROTOCOL://$HOSTNAME"
echo
echored "Below is admin information which can be used to login into administration page"
echored "admin username : admin and admin password : $MAGENTO_ADMIN_PASSWORD_DEFAULT"
