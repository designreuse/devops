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

# export BASE_WP=~
export WEBSERVER_PATH=/var/www
export MONICA_USER=monica
# export PHP_VERSION=7.0
export PHP_VERSION=7.1


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

if [ "$(which nginx)" = "" ]; then
  if [ -f "S0.os-upgrade.sh" ]; then
  . S0.os-upgrade.sh
  else
    . ../S0.os-upgrade.sh
  fi
fi

if [ "$(which mysql)" = "" ]; then
  . $BASE_INSTALL/scripts/mariadb.sh
fi
  
# Install php
if [ "$(which php)" = "" ]; then
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "Installing PHP for system."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  sudo add-apt-repository ppa:ondrej/php
  sudo apt-get update
  # sudo apt-get install php7.1 php7.1-cli php7.1-common php7.1-json php7.1-opcache \
  #   php7.1-mysql php7.1-mbstring php7.1-mcrypt php7.1-zip php7.1-fpm php7.1-bcmath \
  #   php7.1-intl php7.1-simplexml php7.1-dom php7.1-curl php7.1-gd
  # sudo apt-get $APTVERBOSITY install php$PHP_VERSION-fpm php$PHP_VERSION-mcrypt php$PHP_VERSION-curl php$PHP_VERSION-cli php$PHP_VERSION-mysql php$PHP_VERSION-gd php$PHP_VERSION-xsl php$PHP_VERSION-json php$PHP_VERSION-intl php-pear php$PHP_VERSION-dev php$PHP_VERSION-common php$PHP_VERSION-mbstring php$PHP_VERSION-zip php-soap php$PHP_VERSION-bcmath php$PHP_VERSION-imap php$PHP_VERSION-xml php$PHP_VERSION-xmlrpc php$PHP_VERSION-mysql php$PHP_VERSION-gettext
  sudo apt-get $APTVERBOSITY install php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-json php$PHP_VERSION-opcache \
       php$PHP_VERSION-mysql php$PHP_VERSION-mbstring php$PHP_VERSION-mcrypt php$PHP_VERSION-zip php$PHP_VERSION-fpm php$PHP_VERSION-bcmath \
       php$PHP_VERSION-intl php$PHP_VERSION-simplexml php$PHP_VERSION-dom php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-imap
  
  echoblue "PHP installation has been completed"
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
    sudo mkdir ~/.composer
    sudo chmod -R 775 ~/.composer
    sudo chown -R www-data:www-data ~/.composer
  else
    echo "Cannot find composer.phar, we check and try again."
    exit 1
  fi
  echoblue "Composer has been installed successfully"
fi

# Add php config
if [ -f "/etc/php/$PHP_VERSION/fpm/php.ini" ]; then
  sudo sed -i "s/\(^memory_limit =\).*/\1 2048M/" /etc/php/$PHP_VERSION/fpm/php.ini
  sudo sed -i "s/\(^max_execution_time =\).*/\1 3600/" /etc/php/$PHP_VERSION/fpm/php.ini
  sudo sed -i "s/\(^zlib.output_compression =\).*/\1 On/" /etc/php/$PHP_VERSION/fpm/php.ini
  sudo sed -i "s/\(^zmax_input_time =\).*/\1 300/" /etc/php/$PHP_VERSION/fpm/php.ini
  sudo sed -i "s/\(^zpost_max_size =\).*/\1 512M/" /etc/php/$PHP_VERSION/fpm/php.ini
  sudo sed -i "s/\(^zupload_max_filesize =\).*/\1 256M/" /etc/php/$PHP_VERSION/fpm/php.ini
  sudo sed -i "s/\(^zmax_file_uploads =\).*/\1 60/" /etc/php/$PHP_VERSION/fpm/php.ini
  # sudo sed -i "s/\(^zdate.timezone =\).*/\1 Asia/Ho_Chi_Minh/" /etc/php/$PHP_VERSION/fpm/php.ini
  echo 'date.timezone = Asia/Ho_Chi_Minh' | sudo tee --append /etc/php/$PHP_VERSION/fpm/php.ini

  sudo systemctl restart php$PHP_VERSION-fpm
else
  echo "There is no file php.ini, please check if php is installed correctly."
fi


# cd $BASE_WP
cd $WEBSERVER_PATH

if [ -d "$WEBSERVER_PATH/$MONICA_USER" ]; then
  sudo rm -rf $WEBSERVER_PATH/$MONICA_USER
fi

if [ ! -d "$WEBSERVER_PATH/$MONICA_USER" ]; then
  git clone https://vbosstech@github.com/vbosstech/$MONICA_USER.git $WEBSERVER_PATH/$MONICA_USER
else
  cd $WEBSERVER_PATH/$MONICA_USER
  git pull
fi

# sudo chown -R www-data:www-data /var/www/$MONICA_USER
sudo find . -type d -exec chmod 755 {} \;
sudo find . -type f -exec chmod 644 {} \;
sudo chown -R $USER:www-data .
# sudo php app/console cache:clear --env=prod
cd $WEBSERVER_PATH/$MONICA_USER
# sudo rsync -avz README/$MONICA_USER/ /var/www/$MONICA_USER/
# sudo -u www-data composer install
sudo composer install --no-interaction --no-suggest --no-dev

read -e -p "Create Monica user? [y/n] " -i "y" createmonicacuser
if [ "$createmonicacuser" = "y" ]; then
  read -s -p "Enter the Monica database password:" MONICA_PASSWORD
  echo ""
  read -s -p "Re-Enter the Monica database password:" MONICA_PASSWORD2
  while [ "$MONICA_PASSWORD" != "$MONICA_PASSWORD2" ]; do
    echo "Password does not match. Please try again"
    read -s -p "Enter the Monica database password:" MONICA_PASSWORD
    echo ""
    read -s -p "Re-Enter the Monica database password:" MONICA_PASSWORD2
  done
    echo "Creating Monica database and user."
    echo "You must supply the root user password for MariaDB:"
    mysql -u root -p << EOF
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
    CREATE DATABASE monica;
    # create $MONICA_USER user
    DELETE FROM mysql.user WHERE User = '$MONICA_USER';
    CREATE USER '$MONICA_USER'@'localhost' IDENTIFIED BY '$MONICA_PASSWORD';
    GRANT ALL PRIVILEGES ON monica.* TO '$MONICA_USER'@'localhost' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
EOF
  echo
  echo
  
fi

read -e -p "Please enter the public host name for Monica server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" MONICA_HOSTNAME
read -e -p "Please enter the protocol for Monica server (fully qualified domain name)${ques} [http] " -i "http" MONICA_PROTOCOL

if [ -n "$MONICA_HOSTNAME" ]; then
  if [ "${MONICA_PROTOCOL,,}" = "https" ]; then
    if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
      . $BASE_INSTALL/scripts/ssl.sh  $MONICA_HOSTNAME
    else
      . scripts/ssl.sh $MONICA_HOSTNAME
    fi
  else
     sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$MONICA_HOSTNAME.conf
     sudo ln -s /etc/nginx/sites-available/$MONICA_HOSTNAME.conf /etc/nginx/sites-enabled/
      
     sudo sed -i "s/@@DNS_DOMAIN@@/$MONICA_HOSTNAME/g" /etc/nginx/sites-available/$MONICA_HOSTNAME.conf
  fi
  sudo sed -i "s/##WEB_ROOT##/root \/var\/www\/$MONICA_USER;/g" /etc/nginx/sites-available/$MONICA_HOSTNAME.conf
  sudo sed -i "s/##INDEX##/index index.php index.html index.htm index.nginx-debian.html;/g" /etc/nginx/sites-available/$MONICA_HOSTNAME.conf
   
  
  sudo mkdir temp
  sudo cp $NGINX_CONF/sites-available/$MONICA_USER.snippet  temp/
  sudo sed -e '/##MONICA##/ {' -e 'r temp/monica.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$MONICA_HOSTNAME.conf
  sudo rm -rf temp

fi

cd $WEBSERVER_PATH/$MONICA_USER
sudo find . -type d -exec chmod 755 {} \;
sudo find . -type f -exec chmod 644 {} \;
sudo chown -R $USER:www-data .
sudo chgrp -R www-data $MONICA_USER
sudo chmod -R 775 $MONICA_USER/storage

sudo php artisan key:generate
sudo php artisan setup:production
sudo php artisan passport:install
sudo php artisan schedule:run

sudo service nginx restart

echogreen "After you login into the home page, you will see profile avatar broken, the reason is Monica will get avatar picture from http://www.gravatar.com via email"
echogreen " so you should use your email to register an account in http://www.gravatar.com "