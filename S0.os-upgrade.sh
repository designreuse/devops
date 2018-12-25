#!/bin/bash
# -------
# Ubuntu 16.04 Scripts to check and initialize all necessary stuffs before running DevOps
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi

# size of swapfile in megabytes = 2X
# default is 8192MB (8GBx1024); 16384MB (16GBx1024)
swapsize=32G


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Preparing for install. Updating and upgrading the apt package index files..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY update && sudo apt-get $APTVERBOSITY upgrade;
echo

##
# Swap File
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Starting to create Swap space..."
echo "Swap space/partition is space on a disk created for use by the operating system when memory has been fully utilized." 
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
	echo "swapfile not found. Adding swapfile. Swap should be double the amount of 16GB RAM"
	sudo fallocate -l ${swapsize} /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile

  # Back up the /etc/fstab
  sudo cp /etc/fstab /etc/fstab.bak
  echo '/swapfile none swap sw 0 0' | sudo tee --append /etc/fstab
  echo "vm.swappiness=20"           | sudo tee --append /etc/sysctl.conf
  echo "vm.vfs_cache_pressure=60"   | sudo tee --append /etc/sysctl.conf
else
	echo "swapfile already exists. Skipping adding swapfile."
fi


echo "Showing swap info....."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# output results to terminal
# cat /proc/swaps
# cat /proc/meminfo | grep Swap
free -h
sudo swapon --show
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

sudo locale-gen $LOCALESUPPORT
sudo update-locale LC_ALL=$LOCALESUPPORT
# sudo dpkg-reconfigure locales
# sudo echo "LC_ALL=en_US.UTF-8" >> /etc/environment
# sudo echo "LANG=en_US.UTF-8" >> /etc/environment

##
# Timezone
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Begin setting up TimeZone..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo timedatectl set-timezone $TIME_ZONE


if [ "`which curl`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install curl. Curl is used for downloading components to install."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install curl;
fi

if [ "`which wget`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install wget. Wget is used for downloading components to install."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install wget;
fi

# if [ "`which rsync`" = "" ]; then
# 	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# 	echo "You need to install rsync. rsync is used for copying or synchronizing data in local or remote ."
# 	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# 	sudo apt-get $APTVERBOSITY install rsync;
# fi

if [ "`which zip`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install zip. zip is used for compressing data."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install zip;
fi

if [ "`which unzip`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install unzip. unzip is used for uncompressing data ."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install unzip;
fi

# if [ "`which git`" = "" ]; then
# 	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# 	echo "You need to install git."
# 	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# 	sudo apt-get $APTVERBOSITY install git;
# 	sudo chown -R $USER:$USER ~/.config
# fi

if [ "`which aws`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install awscli."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install awscli;
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

  sudo apt-get $APTVERBOSITY update
  sudo apt-get $APTVERBOSITY install nginx
  
  # Enable Nginx to auto start when Ubuntu is booted
  sudo systemctl enable nginx
  
  # Insert config for letsencrypt
  if [ ! -d "/opt/letsencrypt/.well-known" ]; then
  sudo mkdir -p /opt/letsencrypt/.well-known
  echo "Hello Letsencrypt!" | sudo tee /opt/letsencrypt/index.html
  fi
  
  sudo chown -R www-data:root /opt/letsencrypt
  
  if [ -f "/etc/nginx/sites-available/default" ]; then
      # Check if eform config does exist
    well_known=$(grep -o "well-known" /etc/nginx/sites-available/default | wc -l)
    
    if [ $well_known = 0 ]; then
       sudo sed -i '/^\(}\)/ i location \/\.well-known {\n  alias \/opt\/letsencrypt\/\.well-known\/;\n  allow all;  \n  }' /etc/nginx/sites-available/default
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
  sudo systemctl restart nginx
  
  sudo ufw enable
 
  count=1
  while read line || [[ -n "$line" ]] ;
  do
    count=`expr $count + 1`
    if [ $count -gt 3 ]; then
      IFS='|' read -ra arr <<<"$line"
      port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      if [[ $port =~ '^[0-9]+$' ]]; then
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
# Java 8 SDK
##
if [ "`which java`" = "" ]; then
  echoblue "Installing Oracle Java 8. Fetching packages..."

  JDK_VERSION=`echo $JAVA8URL | rev | cut -d "/" -f1 | rev`

  declare -a PLATFORMS=("-linux-x64.tar.gz")

  for platform in "${PLATFORMS[@]}"
  do
     wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" "${JAVA8URL}${platform}" -P $TMP_INSTALL
     ### curl -C - -L -O -# -H "Cookie: oraclelicense=accept-securebackup-cookie" "${JAVA8URL}${platform}"
  done
  sudo mkdir /usr/java
  sudo tar xvzf $TMP_INSTALL/jdk-$JAVA_VERSION-linux-x64.tar.gz -C /usr/java
  
  JAVA_DEST=jdk1.8.0_181
  export JAVA_HOME=/usr/java/$JAVA_DEST/
  sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 1
  sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 1

  echo
  echogreen "Finished installing Oracle Java 8"
  echo
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
  wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
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
		jenkins_port=8899
		read -e -p "Please enter the public host name for Jenkins server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" JENKINS_HOSTNAME
	fi
  fi
  sudo sed -i "s/\(^HTTP_PORT=\).*/\1$jenkins_port/" /etc/default/jenkins
  sudo ufw allow $jenkins_port
  sudo systemctl start jenkins
  # sudo apt-get remove --purge jenkins
  # sudo sed -i "s/@@PORT@@/$jenkins_port/g" /etc/nginx/sites-available/$JENKINS_HOSTNAME.conf

  ## Allow Jenkins can read write to /var/www/html
  sudo chown -R jenkins:jenkins /var/www/html
  
  jenkins_sudo_found=$(sudo grep -o "jenkins" /etc/sudoers | wc -l)
  if [ $jenkins_sudo_found = 0 ]; then
	# Add jenkins to sudoers
	echo "jenkins ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
  fi
  sudo service jenkins restart
  sudo service nginx restart
fi

sleep 5
echogreen "This is the initial admin password for Jenkins : $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"

##
# System devops user
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to add a system user that runs the tomcat Devops instance."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add devops system user${ques} [y/n] " -i "$DEFAULTYESNO" adddevops
if [ "$adddevops" = "y" ]; then
  sudo adduser --system --disabled-login --disabled-password --group $DEVOPS_USER
  sudo adduser ubuntu $DEVOPS_USER
  sudo adduser jenkins $DEVOPS_USER
  echo
  echogreen "Finished adding devops user"
  echo
else
  echo "Skipping adding devops user"
  echo
fi


##############################
# Docker & Docker-Compose
##############################
if [ "`which docker`" = "" ]; then
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You need to install Docker & Docker-Compose"
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  sudo curl -fsSL get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  # docker volume ls
  # docker volume prune
fi

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

##Python##
if [ "`which python`" = "" ]; then
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You need to install python."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  sudo apt-get $APTVERBOSITY install python;
fi

##Pip##
if [ "`which pip`" = "" ]; then
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You need to install python pip."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  sudo apt-get $APTVERBOSITY install python-pip;
  sudo pip install --upgrade pip
  sudo pip install awscli --upgrade --user
fi


########
# MkDocs
########
if [ "`which mkdocs`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install MkDocs & Mkdocs-Material."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  sudo pip install mkdocs
  sudo pip install mkdocs-material
fi

## Install Jekyll
if [ "`which jekyll`" = "" ]; then
  sudo apt-get update
  sudo apt-get install ruby ruby-dev make gcc build-essential patch zlib1g-dev liblzma-dev
  sudo gem install jekyll bundler
fi

##############################
# Remote login
##############################
read -e -p "Do you want to ssh to server remotely by providing username and password${ques} [y/n] " -i "$DEFAULTYESNO" sshremote
if [ "$sshremote" = "y" ]; then
	sudo sed -i "s/\(^PasswordAuthentication \).*/\1yes/" /etc/ssh/sshd_config
	sudo service sshd restart
	sudo usermod --password $(echo PASSWORD | openssl passwd -1 -stdin) $USER
	echogreen "User can ssh to server by using this command : ssh -o PreferredAuthentications=password user@ip"
fi