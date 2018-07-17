#!/bin/bash
# -------
# Script to check and initialize all necessary stuffs before running devops
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

# size of swapfile in megabytes = 2X
# default is 8192MB (8GBx1024); 16384MB (16GBx1024)
swapsize=16G


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Preparing for install. Updating and upgrading the apt package index files..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY update && sudo apt-get $APTVERBOSITY upgrade;
echo

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

if [ "`which rsync`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install rsync. rsync is used for copying or synchronizing data in local or remote ."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install rsync;
fi

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

if [ "`which git`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install git."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install git;
	sudo chown -R $USER:$USER ~/.config
fi

if [ "`which python`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install python."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install python;
fi

if [ "`which pip`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install python pip."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install python-pip;
	sudo pip install --upgrade pip
	sudo pip install awscli --upgrade --user

	# Install MkDocs & MkDocs-Material 
	sudo pip install mkdocs
	sudo pip install mkdocs-material
fi

if [ "`which aws`" = "" ]; then
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to install awscli."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt-get $APTVERBOSITY install awscli;
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
  
  JAVA_DEST=jdk1.8.0_171
  export JAVA_HOME=/usr/java/$JAVA_DEST/
  sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 1
  sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 1

  echo
  echogreen "Finished installing Oracle Java 8"
  echo
fi


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
	echo "swapfile not found. Adding swapfile. Swap should be double the amount of 8GB RAM"
	sudo fallocate -l ${swapsize} /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
	# echo "/swapfile none swap defaults 0 0" >> /etc/fstab
else
	echo "swapfile already exists. Skipping adding swapfile."
fi

# Back up the /etc/fstab
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee --append /etc/fstab

echo "vm.swappiness=20"           | sudo tee --append /etc/sysctl.conf
echo "vm.vfs_cache_pressure=60"   | sudo tee --append /etc/sysctl.conf

echo "Showing swap info....."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
# output results to terminal
# cat /proc/swaps
# cat /proc/meminfo | grep Swap
free -h
sudo swapon --show
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

sudo locale-gen en_US.utf8
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