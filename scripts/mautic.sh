#!/bin/bash
# Configure and install ocr services
#

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
else
	. ../constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
else
	. ../colors.sh	
fi

export BASE_WP=~
export MAUTIC_USER=mautic


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

if [ "$(which nginx)" = "" ]; then
	if [ -f "1.ubuntu-upgrade.sh" ]; then
	. 1.ubuntu-upgrade.sh
	else
		. ../1.ubuntu-upgrade.sh
	fi
fi

# Install php
if [ "$(which php)" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Installing php for system."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install php$PHP_VERSION-fpm php$PHP_VERSION-mcrypt php$PHP_VERSION-curl php$PHP_VERSION-cli php$PHP_VERSION-mysql php$PHP_VERSION-gd php$PHP_VERSION-xsl php$PHP_VERSION-json php$PHP_VERSION-intl php-pear php$PHP_VERSION-dev php$PHP_VERSION-common php$PHP_VERSION-mbstring php$PHP_VERSION-zip php-soap php$PHP_VERSION-bcmath 
	echoblue "PHP installation has been completed"
else
	# Maybe we installed php earlier without php-bcmath
	sudo apt-get install php$PHP_VERSION-bcmath
fi

echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Composer is an PHP dependency management tool...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# Install composer
if [ "$(which composer)" = "" ]; then
	if [ ! -d "$TMP_INSTALL" ]; then
		mkdir $TMP_INSTALL
	fi	
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


cd $BASE_WP

if [ -d "/var/www/mautic" ]; then
	sudo rm -rf /var/www/mautic
fi

if [ ! -d "$BASE_WP/mautic" ]; then
  git clone https://github.com/mautic/mautic.git	$BASE_WP/mautic
else
  cd $BASE_WP/mautic
  git pull
fi

sudo rsync -avz $BASE_WP/mautic /var/www/

sudo chown -R www-data:www-data /var/www/mautic
cd /var/www/mautic/
sudo -u www-data composer install

if [ "$(which mysql)" = "" ]; then
	. $BASE_INSTALL/scripts/mariadb.sh
fi

read -e -p "Create Mautic user? [y/n] " -i "y" createmauticuser
if [ "$createmauticuser" = "y" ]; then
  read -s -p "Enter the Mautic database password:" MAUTIC_PASSWORD
  echo ""
  read -s -p "Re-Enter the Mautic database password:" MAUTIC_PASSWORD2
  while [ "$MAUTIC_PASSWORD" != "$MAUTIC_PASSWORD2" ]; do
		echo "Password does not match. Please try again"
		read -s -p "Enter the Mautic database password:" MAUTIC_PASSWORD
		echo ""
		read -s -p "Re-Enter the Mautic database password:" MAUTIC_PASSWORD2
  done
    echo "Creating Mautic database and user."
    echo "You must supply the root user password for MariaDB:"
    mysql -u root -p << EOF
    #create mautic user
    DELETE FROM mysql.user WHERE User = '$MAUTIC_USER';
    CREATE USER '$MAUTIC_USER'@'localhost' IDENTIFIED BY '$MAUTIC_PASSWORD';
    GRANT ALL PRIVILEGES ON *.* TO '$MAUTIC_USER'@'localhost' WITH GRANT OPTION;
	FLUSH PRIVILEGES;
EOF
  echo
  echo
  
fi

read -e -p "Please enter the public host name for Mautic server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" MAUTIC_HOSTNAME
read -e -p "Please enter the protocol for MAUTIC server (fully qualified domain name)${ques} [http] " -i "http" MAUTIC_PROTOCOL

if [ -n "$MAUTIC_HOSTNAME" ]; then
	if [ "${MAUTIC_PROTOCOL,,}" = "https" ]; then
		if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
			. $BASE_INSTALL/scripts/ssl.sh	$MAUTIC_HOSTNAME
		else
			. scripts/ssl.sh $MAUTIC_HOSTNAME
		fi
	else
		 sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$MAUTIC_HOSTNAME.conf
		 sudo ln -s /etc/nginx/sites-available/$MAUTIC_HOSTNAME.conf /etc/nginx/sites-enabled/
		  
		 sudo sed -i "s/@@DNS_DOMAIN@@/$MAUTIC_HOSTNAME/g" /etc/nginx/sites-available/$MAUTIC_HOSTNAME.conf
	fi
	sudo sed -i "s/##WEB_ROOT##/root \/var\/www\/mautic;/g" /etc/nginx/sites-available/$MAUTIC_HOSTNAME.conf
	sudo sed -i "s/##INDEX##/index index.php index.html index.htm index.nginx-debian.html;/g" /etc/nginx/sites-available/$MAUTIC_HOSTNAME.conf
	 
	
	sudo mkdir temp
	sudo cp $NGINX_CONF/sites-available/mautic.snippet	temp/
	sudo sed -e '/##MAUTIC##/ {' -e 'r temp/mautic.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$MAUTIC_HOSTNAME.conf
	sudo rm -rf temp
	
	sudo service nginx restart
fi

echogreen "After you login into the home page, you will see profile avatar broken, the reason is mautic will get avatar picture from http://www.gravatar.com via email"
echogreen " so you should use your email to register an account in http://www.gravatar.com "

