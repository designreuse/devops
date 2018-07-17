#!/bin/bash
# -------
# This is standalone script which configure and install pre-environment
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

# Create temporary folder for storing downloaded files
if [ ! -d "$TMP_INSTALL" ]; then
	sudo mkdir -p $TMP_INSTALL
fi

if [ "$(which curl)" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install curl. Curl is used for downloading components to install."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install curl

	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Finish installation of curl."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
fi

##
# Nginx
##
if [ "$(which nginx)" = "" ]; then
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Nginx can be used as frontend to Tomcat."
	echo "This installation will add config default proxying to tomcat running behind."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Install nginx${ques} [y/n] " -i "$DEFAULTYESNO" installnginx
	if [ "$installnginx" = "y" ]; then

		# Remove nginx if already installed
		if [ "$(which nginx)" != "" ]; then
			sudo apt-get remove --auto-remove nginx nginx-common
			sudo apt-get purge --auto-remove nginx nginx-common
		fi
		echoblue "Installing nginx. Fetching packages..."
		echo

		#@Deprecated
		#sudo -s << EOF
		#  echo "deb http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" >> /etc/apt/sources.list
		#  sudo curl -# -o $TMP_INSTALL/nginx_signing.key http://nginx.org/keys/nginx_signing.key
		#  apt-key add $TMP_INSTALL/nginx_signing.key
		#echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu $(lsb_release -cs) main" >> /etc/apt/sources.list
		#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
		# Alternate with spdy support and more, change  apt install -> nginx-custom
		#echo "deb http://ppa.launchpad.net/brianmercer/nginx/ubuntu $(lsb_release -cs) main" >> /etc/apt/sources.list
		#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8D0DC64F
		#EOF

		sudo apt-get $APTVERBOSITY update && sudo apt-get $APTVERBOSITY install nginx
		sudo systemctl enable nginx

		echo "Inserting letsencrypt configuration for nginx..."

		# Insert config for letsencrypt
		if [ -f "/etc/nginx/sites-available/default" ]; then
			sudo sed -i '/^\(}\)/ i location \/\.well-known {\n  alias \/opt\/letsencrypt\/\.well-known\/;\n  allow all;	\n  }' /etc/nginx/sites-available/default
		fi

		## Reload config file
		#TODO: sudo service nginx start
		sudo systemctl restart nginx

		sudo ufw enable
		if [ ! -f "/etc/ufw/applications.d/nginx.ufw.profile" ]; then
			echo "Setting up firewall configuration for nginx..."
			echo "There is no profile for nginx within ufw, so we decide to create it."
			sudo echo "
[Nginx HTTP]
title=Web Server (Nginx, HTTP)
description=Small, but very powerful and efficient web server
ports=80/tcp

[Nginx HTTPS]
title=Web Server (Nginx, HTTPS)
description=Small, but very powerful and efficient web server
ports=443/tcp

[Nginx Full]
title=Web Server (Nginx, HTTP + HTTPS)
description=Small, but very powerful and efficient web server
ports=80,443/tcp
" | sudo tee /etc/ufw/applications.d/nginx.ufw.profile

			sudo ufw app update nginx
		fi

		sudo ufw allow 'Nginx HTTP'
		sudo ufw allow 'Nginx HTTPS'
		sudo ufw allow 'OpenSSH'

		echo
		echogreen "Finished installing nginx"
		echo
	else
		echo "Skipping install of nginx"
	fi
fi

# Install php
if [ "$(which php)" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Installing php for system."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install php$PHP_VERSION-fpm php$PHP_VERSION-mcrypt php$PHP_VERSION-curl php$PHP_VERSION-cli php$PHP_VERSION-mysql php$PHP_VERSION-gd php$PHP_VERSION-xsl php$PHP_VERSION-json php$PHP_VERSION-intl php-pear php$PHP_VERSION-dev php$PHP_VERSION-common php$PHP_VERSION-mbstring php$PHP_VERSION-zip php-soap php$PHP_VERSION-bcmath
	echoblue "PHP installation has been completed"
fi

echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Composer is an PHP dependency management tool...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# Install composer
if [ "$(which composer)" = "" ]; then

	echo "Downloading Composer to temporary folder..."
	curl -# -o $TMP_INSTALL/composer $COMPOSERURL
	sudo php $TMP_INSTALL/composer

	# Install composer globally
	if [ -f "composer.phar" ]; then
		sudo mv composer.phar /usr/local/bin/composer
	else
		echo "Cannot find composer.phar, we check and try again."
		exit 1
	fi
	echoblue "Composer has been installed successfully"
fi

# Add php config
if [ -f "/etc/php/$PHP_VERSION/fpm/php.ini" ]; then
	sudo sed -i "s/\(^memory_limit =\).*/\1 1024M/" /etc/php/$PHP_VERSION/fpm/php.ini
	sudo sed -i "s/\(^max_execution_time =\).*/\1 1800/" /etc/php/$PHP_VERSION/fpm/php.ini
	sudo sed -i "s/\(^zlib.output_compression =\).*/\1 On/" /etc/php/$PHP_VERSION/fpm/php.ini

	sudo systemctl restart php7.0-fpm
else
	echo "There is no file php.ini, please check if php is installed correctly."
fi

if [ ! -d "$MAGENTO_WEB_ROOT" ]; then
	sudo mkdir -p $MAGENTO_WEB_ROOT
fi

# Create authentication file for magento
if [ ! -f "$AUTHENTICATE_FILE" ]; then
	echo "Generating magento authentication json."
	sudo echo "
{
   \"http-basic\": {
     \"repo.magento.com\": {
        \"username\":\"@@AUTHENTICATE_USERNAME@@\",
        \"password\":\"@@AUTHENTICATE_PASSWORD@@\"
     }
   }
} 
" | sudo tee $AUTHENTICATE_FILE

	sudo sed -i "s/@@AUTHENTICATE_USERNAME@@/$AUTHENTICATE_USERNAME/g" $AUTHENTICATE_FILE
	sudo sed -i "s/@@AUTHENTICATE_PASSWORD@@/$AUTHENTICATE_PASSWORD/g" $AUTHENTICATE_FILE
fi

##
# Database
##
if [ "$(which mysql)" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Install Database"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Please select on of these : [PE]rcona, [MA]riadb, [Q]uit " -i "$DEFAULTDB" installdb

	case $installdb in
	"PE")
		echo "Choosing Percona..."
		sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
		sudo bash -c 'echo deb http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
		sudo bash -c 'echo deb-src http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
		sudo apt-get update
		read -e -p "Please choose a version of Percona${ques} " -i "5.6" PERCONA_VERSION
		echo "percona-server-server-$PERCONA_VERSION percona-server-server/root_password password root" | sudo debconf-set-selections
		echo "percona-server-server-$PERCONA_VERSION percona-server-server/root_password_again password root" | sudo debconf-set-selections
		sudo apt-get install -qq -y percona-server-server-$PERCONA_VERSION percona-server-client-$PERCONA_VERSION
		echo "Database has been installed successfully with root information as following : "
		echored "username : root & password : root"
		;;
	"MA")
		echo "Choosing mariadb..."
		sudo apt-get install software-properties-common
		sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
		sudo add-apt-repository "deb [arch=amd64,i386,ppc64el] http://ftp.ddg.lth.se/mariadb/repo/10.1/ubuntu $(lsb_release -cs) main"
		sudo apt-get update
		sudo apt-get $APTVERBOSITY install mariadb-server
		sudo mysql_secure_installation
		#Tuning database by setting config
		sudo echo "key_buffer_size         = 128M" | sudo tee /etc/mysql/conf.d/mariadb.cnf
		sudo echo "max_allowed_packet      = 128M" | sudo tee /etc/mysql/conf.d/mariadb.cnf
		sudo echo "thread_stack            = 1024K" | sudo tee /etc/mysql/conf.d/mariadb.cnf
		sudo echo "innodb_log_file_size    = 128M" | sudo tee /etc/mysql/conf.d/mariadb.cnf
		;;
	"Q")
		echo "Quitting..."
		;;
	*) echo "invalid option" ;;
	esac
fi
