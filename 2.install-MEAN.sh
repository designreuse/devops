#!/bin/bash
# -------
# Script to configure and setup Nginx, NVM, PM2, Nodejs, Redis, MongoDB, Jenkins, CertbotSSL, SSL
#
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


URLERROR=0

for REMOTE in $NVMURL $NODEJSURL
do
        wget --spider $REMOTE --no-check-certificate >& /dev/null
        if [ $? != 0 ]
        then
                echored "Please fix this URL: $REMOTE and try again later"
                URLERROR=1
        fi
done

if [ $URLERROR = 1 ]
then
    echo
    echored "Please fix the above errors and rerun."
    echo
    exit
fi

# Create temporary folder for storing downloaded files
if [ ! -d "$TMP_INSTALL" ]; then
  mkdir -p $TMP_INSTALL
fi


##
# Nginx
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Nginx can be used as frontend to Tomcat."
echo "This installation will add config default proxying to tomcat running behind."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install nginx${ques} [y/n] " -i "$DEFAULTYESNO" installnginx
if [ "$installnginx" = "y" ]; then

  # Remove nginx if already installed
  if [ "`which nginx`" != "" ]; then
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

  sudo apt-get $APTVERBOSITY update
  sudo apt-get $APTVERBOSITY install nginx
  # Enable Nginx to auto start when Ubuntu is booted
  sudo systemctl enable nginx
  # Check Nginx status
  # systemctl status nginx
  
  # TODO: sudo service nginx stop
  # sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
  # sudo mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.sample
  
  # WEB_ROOT=$WORKFORCE_HOME/www
  
  # Make the ssl dir as this is what is used in sample config
  # TODO: sudo mkdir -p /etc/nginx/ssl
  
  # Compatible with Apache, we check if there is already existing apache web root. If it is, we use it by default. 
  # If not, $WORKFORCE_HOME should be a folder contains webroot
  # if [ ! -d "/var/www" ]; then
	# sudo mkdir -p $WORKFORCE_HOME/www
  # else
	# WEB_ROOT="/var/www"
  #fi
  
#  sudo mkdir -p /var/cache/nginx/workforce
  #if [ ! -f "$WEB_ROOT/www/maintenance.html" ]; then
  #  echo "Copying maintenance html page..."
#	sudo rsync -avz $NGINX_CONF/maintenance.html $WEB_ROOT
#  fi
#  sudo chown -R www-data:root /var/cache/nginx/workforce
#  sudo chown -R www-data:root $WEB_ROOT
  #TODO: sudo chown -R www-data:root /usr/share/nginx
  
#  sudo chmod 2775 $WEB_ROOT
#  sudo find $WEB_ROOT -type d -exec sudo chmod 2775 {} \;
#  sudo find $WEB_ROOT -type f -exec sudo chmod 0664 {} \;
  
#  sudo rsync -avz $NGINX_CONF/ /etc/nginx/
#  if [ ! -f "/etc/nginx/maintenance.html" ]; then
#	rm -f /etc/nginx/maintenance.html
#  fi
  
  #escape for sed
#  WEB_ROOT_PATH="${WEB_ROOT//\//\\/}"
#  sed -i "s/@@WEB_ROOT@@/$WEB_ROOT_PATH/g" /etc/nginx/conf.d/workforce.conf
#  sed -i "s/@@WEB_ROOT@@/$WEB_ROOT_PATH/g" /etc/nginx/conf.d/workforce.conf.ssl

  # Insert config for letsencrypt
  if [ ! -d "/opt/letsencrypt/.well-known" ]; then
	sudo mkdir -p /opt/letsencrypt/.well-known
	echo "Hello Letsencrypt!" | sudo tee /opt/letsencrypt/index.html
  fi
  
  sudo chown -R www-data:root /opt/letsencrypt
  
  # if [ ! -f "/etc/nginx/conf.d/default.conf" ]; then
  # sudo rsync -avz $NGINX_CONF/conf.d/default.conf /etc/nginx/conf.d/		
  # else
  # sudo sed -i '/^\(}\)/ i location \/\.well-known {\n  alias \/opt\/letsencrypt\/\.well-known\/;\n  allow all;	\n  }' /etc/nginx/conf.d/default.conf
  # fi
  
  if [ -f "/etc/nginx/sites-available/default" ]; then
      # Check if eform config does exist
    well_known=$(grep -o "well-known" /etc/nginx/sites-available/default | wc -l)
    
    if [ $well_known = 0 ]; then
	     sudo sed -i '/^\(}\)/ i location \/\.well-known {\n  alias \/opt\/letsencrypt\/\.well-known\/;\n  allow all;	\n  }' /etc/nginx/sites-available/default
     fi
  fi
  
  if [ ! -f "/etc/nginx/snippets/ssl.conf" ]; then
	sudo echo "
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

ssl_protocols TLSv1.2;
ssl_ciphers EECDH+AESGCM:EECDH+AES;
ssl_ecdh_curve secp384r1;
ssl_prefer_server_ciphers on;

ssl_stapling on;
ssl_stapling_verify on;

add_header Strict-Transport-Security \"max-age=15768000; includeSubdomains; preload\";
add_header X-Content-Type-Options nosniff;
" | sudo tee /etc/nginx/snippets/ssl.conf
  fi
  
  ## Reload config file
  #TODO: sudo service nginx start
  sudo systemctl restart nginx
  
  sudo ufw enable
#   if [ ! -f "/etc/ufw/applications.d/nginx.ufw.profile" ]; then
# 	echo "There is no profile for nginx within ufw, so we decide to create it."
# 	sudo cat <<EOF >/etc/ufw/applications.d/nginx.ufw.profile
# [Nginx HTTP]
# title=Web Server (Nginx, HTTP)
# description=Small, but very powerful and efficient web server
# ports=80/tcp

# [Nginx HTTPS]
# title=Web Server (Nginx, HTTPS)
# description=Small, but very powerful and efficient web server
# ports=443/tcp

# [Nginx Full]
# title=Web Server (Nginx, HTTP + HTTPS)
# description=Small, but very powerful and efficient web server
# ports=80,443/tcp
# EOF

# 	sudo ufw app update nginx
#   fi
  
	count=1
	while read line || [[ -n "$line" ]] ;
	do
		count=`expr $count + 1`
		if [ $count -gt 3 ]; then
			IFS='|' read -ra arr <<<"$line"
			port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
			if [ $port != "xxxx" ]; then
				sudo ufw allow $port
			fi
		fi
	done < $BASE_INSTALL/domain.txt

  sudo ufw allow 'Nginx HTTP'
  sudo ufw allow 'Nginx HTTPS'
  sudo ufw allow 'OpenSSH'


  echo
  echogreen "Finished installing nginx"
  echo
else
  echo "Skipping install of nginx"
fi

##
# NVM
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Begin setting up a nvm..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install nvm${ques} [y/n] " -i "$DEFAULTYESNO" installnvm
if [ "$installnvm" = "y" ]; then
  curl -# -o $TMP_INSTALL/install.sh $NVMURL
  sh $TMP_INSTALL/install.sh
  echo
  echogreen "Finished installing NVM"

fi

##
# Node JS
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Begin setting up a nodejs..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install nodejs${ques} [y/n] " -i "$DEFAULTYESNO" installnodejs
if [ "$installnodejs" = "y" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Installing & Configuring NodeJS LTS (v6.12.2)"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	curl -sL $NODEJSURL | sudo -E bash -
	sudo apt-get $APTVERBOSITY install nodejs
	sudo npm install -g npm@latest
	
	# [Optional] Some NPM packages will probably throw errors when compiling
	sudo apt-get $APTVERBOSITY install build-essential
fi

##
# PM2
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Begin setting up a PM2..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install PM2${ques} [y/n] " -i "$DEFAULTYESNO" installpm2
if [ "$installpm2" = "y" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install PM2"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo npm install -g pm2
	## TODO: permission-startup.sh
	mkdir /home/$USER/.pm2
	sudo chown $USER:$USER -R /home/$USER/.pm2
	sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER
	
	# We will retry checking whether .pm2 directory exists and change its owner
	# n=0
	# until [ $n -ge 6 ]
	# do
	# 	if [ -d "/home/$USER/.pm2" ]; then
	# 		echo "Regis ubuntu's pm2 run on startup"
	# 		sudo chown $USER:$USER -R /home/$USER/.pm2
	# 		break
	# 	fi
	# 	n=$[$n+1]
	# 	sleep 10
	# done
	# sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER
fi

##
# Redis
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Begin setting up a Redis..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Redis${ques} [y/n] " -i "$DEFAULTYESNO" installredis
if [ "$installredis" = "y" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install Redis"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install redis-server
	# sudo chmod 770 /etc/redis/redis.conf
	echo "maxmemory 1024mb" | sudo tee --append /etc/redis/redis.conf
    echo "maxmemory-policy allkeys-lru" | sudo tee --append /etc/redis/redis.conf
	sudo systemctl enable redis-server.service
fi

##
# MongoDB
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Begin setting up a MongoDB..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install MongoDB${ques} [y/n] " -i "$DEFAULTYESNO" installmongodb
if [ "$installmongodb" = "y" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install MongoDB"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	
	# Import the key for the official MongoDB repository
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
	
    # Create a list file for MongoDB
    echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
	
    sudo apt-get $APTVERBOSITY update
	
    # Install mongodb-org, which includes the daemon, configuration and init scripts, shell, and management tools on the server. 
    sudo apt-get $APTVERBOSITY install -y mongodb-org
	
    # Ensure that MongoDB restarts automatically at boot
    sudo systemctl enable mongod   
    sudo systemctl start mongod
fi

##
# Jenkins
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Jenkins is a en source automation server, Jenkins provides hundreds of plugins to support building, deploying and automating any project "
echo "You will also get the option to install this server"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Jenkins automation server${ques} [y/n] " -i "$DEFAULTYESNO" installjenkins
if [ "$installjenkins" = "y" ]; then
  get -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
  sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  sudo apt-get update
  sudo apt-get -qq -y install jenkins
  jenkins_line=$(grep "jenkins" $BASE_INSTALL/domain.txt)
  IFS='|' read -ra arr <<<"$jenkins_line"
  jenkins_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  JENKINS_HOSTNAME="$(echo -e "${arr[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -z "$jenkins_port" ]; then
	ci_line=$(grep "ci" $BASE_INSTALL/domain.txt)
	IFS='|' read -ra arr1 <<<"$ci_line"
	jenkins_port="$(echo -e "${arr1[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	JENKINS_HOSTNAME="$(echo -e "${arr1[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	if [ -z "$jenkins_port" ]; then
		jenkins_port=8080
		read -e -p "Please enter the public host name for Jenkins server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" JENKINS_HOSTNAME
	fi
  fi
  sudo sed -i "s/\(^HTTP_PORT=\).*/\1$jenkins_port/" /etc/default/jenkins
  sudo systemctl start jenkins
  #read -e -p "Please enter the public host name for Jenkins server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" JENKINS_HOSTNAME
  sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$JENKINS_HOSTNAME.conf
  sudo ln -s /etc/nginx/sites-available/$JENKINS_HOSTNAME.conf /etc/nginx/sites-enabled/
	  
  sudo sed -i "s/@@DNS_DOMAIN@@/$JENKINS_HOSTNAME/g" /etc/nginx/sites-available/$JENKINS_HOSTNAME.conf

  sudo mkdir temp
  sudo cp $NGINX_CONF/sites-available/common.snippet	temp/
  sudo sed -e '/##COMMON##/ {' -e 'r temp/common.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$JENKINS_HOSTNAME.conf
  sudo rm -rf temp
  		  
  sudo sed -i "s/@@PORT@@/$jenkins_port/g" /etc/nginx/sites-available/$JENKINS_HOSTNAME.conf
  sudo service nginx restart
  sudo service jenkins restart
  
  jenkins_sudo_found=$(sudo grep -o "jenkins" /etc/sudoers | wc -l)
  if [ $jenkins_sudo_found = 0 ]; then
	# Add jenkins to sudoers
	echo "jenkins ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
  fi
fi


##
# Certbot SSL
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Certbot SSL"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install certbot${ques} [y/n] " -i "$DEFAULTYESNO" installcertbot
if [ "$installcertbot" = "y" ]; then

  # Remove nginx if already installed
  if [ "`which certbot`" != "" ]; then
    # Uninstall Certbot
    sudo apt-get purge python-certbot-nginx
    sudo rm -rf /etc/letsencrypt
  fi
  echoblue "Installing Certbot. Fetching packages..."
  echo  
  sudo add-apt-repository ppa:certbot/certbot
  sudo apt-get $APTVERBOSITY update
  sudo apt-get $APTVERBOSITY install -y python-certbot-nginx
  echo
  echogreen "Finished installing Certbot"
  echo
else
  echo "Skipping install of Certbot"
fi


##
# SSL @deprecated - using ssl-standalone instead of
##
# echo
# echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# echo "Begin setting up a SSL..."
# echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# read -e -p "Install ssl${ques} [y/n] " -i "$DEFAULTYESNO" installssl
# if [ "$installssl" = "y" ]; then
# 	local_port=443
# 	read -e -p "Please enter the public host name for your server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" hostname
	
# 	if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
# 		.	$BASE_INSTALL/scripts/ssl.sh $hostname
# 	else
# 		. 	scripts/ssl.sh $hostname
# 	fi
# 	sudo mkdir temp
# 	sudo cp $NGINX_CONF/sites-available/common.snippet	temp/
# 	sudo sed -e '/##COMMON##/ {' -e 'r temp/common.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$hostname.conf
# 	sudo sed -i "s/@@PORT@@/8080/g" /etc/nginx/sites-available/$local_domain.conf
# 	sudo rm -rf temp
# fi

