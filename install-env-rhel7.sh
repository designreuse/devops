#!/bin/bash
# -------
# Script to install, configure nginx and certbot for RHEL 7
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

sudo subscription-manager register --username $REDHAT_USER --password $REDHAT_PASSWORD --auto-attach
sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
sudo yum install git docker rsync wget vim firewalld net-tools python-pip -y
sudo pip install docker-compose

##Nginx##
if [ "`which nginx`" = "" ]; then
	sudo echo "
	[nginx]
	name=nginx repo
	baseurl=http://nginx.org/packages/mainline/rhel/7/$basearch/
	gpgcheck=0
	enabled=1
	" | sudo tee /etc/yum.repos.d/nginx.repo
	sudo yum install nginx -y
	sudo sed -i '/^\(}\)/ i location \/\.well-known {\n  alias \/opt\/letsencrypt\/\.well-known\/;\n  allow all;  \n  }' /etc/nginx/conf.d/default.conf
	sudo service nginx restart
	sudo systemctl enable nginx
fi

##
# Certbot SSL
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Certbot SSL"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
if [ "`which certbot`" = "" ]; then
	wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	sudo rpm -ivh epel-release-latest-7.noarch.rpm
	sudo yum install epel-release
	sudo yum -y install yum-utils
	sudo yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional
	sudo yum install -y certbot python-zope-interface --enablerepo="rhel-7-server-rpms" --enablerepo="rhel-7-server-e4s-optional-rpms" --enablerepo=epel
	echo
	echogreen "Finished installing Certbot"
	echo
else
	echo "Skipping install of Certbot"
fi

### TODO: https://certbot.eff.org/lets-encrypt/centosrhel7-nginx.html
# sudo yum install python2-certbot-nginx
# sudo certbot --nginx
###

## Install & Configure firewalld ##
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent
sudo firewall-cmd --reload

# Install postgresql container
sudo docker-compose -f dockers/postgresql.yml up -d

