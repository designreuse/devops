#!/bin/bash
# -------
# This is standalone script which configure and install Alfresco ECM
# -------

# Configure constants
if [ -f "constants.sh" ]; then
	. constants.sh
fi

# Configure colors
if [ -f "colors.sh" ]; then
	. colors.sh
fi

# Escape for sed
ALF_DATA_HOME_PATH="${ALF_DATA_HOME//\//\\/}"
ALFRESCO_HOME_PATH="${DEVOPS_HOME//\//\\/}"

#Enable Smart Folder or not
SF_ENABLE=true

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Begin running...."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

URLERROR=0

for REMOTE in $ALFREPOWAR $ALFSHAREWAR $ALFSHARESERVICES $ALFMMTJAR $AOS_VTI $AOS_SERVER_ROOT $AOS_AMP \
				$SOLR4_WAR_DOWNLOAD $GOOGLEDOCSREPO $GOOGLEDOCSSHARE $LIBREOFFICE $GHOSTSCRIPTURL
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

cd /tmp
if [ ! -d "$TMP_INSTALL" ]; then
  mkdir -p $TMP_INSTALL
fi
  
cd $TMP_INSTALL


if [ "`which systemctl`" = "" ]; then
  export ISON1604=n
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You are installing for version 14.04 (using upstart for services)."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  read -e -p "Is this correct [y/n] " -i "$DEFAULTYESNO" useupstart
  if [ "$useupstart" = "n" ]; then
    export ISON1604=y
  fi
else 
  export ISON1604=y
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You are installing for version 16.04 or later (using systemd for services)."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  read -e -p "Is this correct [y/n] " -i "$DEFAULTYESNO" useupstart
  if [ "$useupstart" = "n" ]; then
    export ISON1604=n
  fi
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Ubuntu default for number of allowed open files in the file system is too low"
echo "for alfresco use and tomcat may because of this stop with the error"
echo "\"too many open files\". You should update this value if you have not done so."
echo "Read more at http://wiki.alfresco.com/wiki/Too_many_open_files"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

count=$(grep -o "alfresco  soft  nofile  8192" /etc/security/limits.conf | wc -l)
if [ $count != 0 ]; then
	echo "limits.conf is already updated, so skipping updating it."
else
	read -e -p "Add limits.conf${ques} [y/n] " -i "$DEFAULTYESNO" updatelimits
	if [ "$updatelimits" = "y" ]; then
	  echo "alfresco  soft  nofile  8192" | sudo tee -a /etc/security/limits.conf
	  echo "alfresco  hard  nofile  65536" | sudo tee -a /etc/security/limits.conf
	  echo
	  echogreen "Updated /etc/security/limits.conf"
	  echo
	  echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
	  echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive
	  echo
	  echogreen "Updated /etc/security/common-session*"
	  echo
	else
	  echo "Skipped updating limits.conf"
	  echo
	fi
fi

##
# Ghostscript
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Ghostscript is used in conjunction with ImageMagick to manipulate images for previewing"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
if [ ! -f "/usr/bin/gs" ]; then
  echogreen "Installing Ghostscript"
  echo "Downloading Ghostscript..."
  curl -# -o $TMP_INSTALL/ghostscript-$GHOSTSCRIPT_VERSION-linux-x86_64.tgz $GHOSTSCRIPTURL
  echo "Extracting..."
  sudo tar -xf $TMP_INSTALL/ghostscript-$GHOSTSCRIPT_VERSION-linux-x86_64.tgz -C $TMP_INSTALL
  sudo mv $TMP_INSTALL/ghostscript-$GHOSTSCRIPT_VERSION-linux-x86_64/gs-918-linux_x86_64 /usr/bin/gs
  sudo ln -s /usr/bin/gs /usr/bin/ghostscript
  echo
  echogreen "Finished installing Ghostscript"
  echo  
else
  echo "Ghostscript is already installed. Skipping install of Ghostscript"
  echo
fi

##
# LibreOffice
##
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install LibreOffice."
echo "This will download and install the latest LibreOffice from libreoffice.org"
echo "Newer version of Libreoffice has better document filters, and produce better"
echo "transformations. If you prefer to use Ubuntu standard packages you can skip"
echo "this install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install LibreOffice${ques} [y/n] " -i "$DEFAULTYESNO" installibreoffice
if [ "$installibreoffice" = "y" ]; then

  cd $TMP_INSTALL
  if [ ! -f "$TMP_INSTALL/LibreOffice_5.1.6.2_Linux_x86-64_deb.tar.gz" ]; then
	echo "Downloading LibreOffice..."
	curl -# -L -O $LIBREOFFICE
  fi
  tar xf LibreOffice*.tar.gz
  cd "$(find . -type d -name "LibreOffice*")"
  cd DEBS
  rm *gnome-integration*.deb &&\
  rm *kde-integration*.deb &&\
  rm *debian-menus*.deb &&\
  sudo dpkg -i *.deb
  echo
  echoblue "Installing some support fonts for better transformations."
  # libxinerama1 libglu1-mesa needed to get LibreOffice 4.4 to work. Add the libraries that Alfresco mention in documentatinas required.

  ###1604 fonts-droid not available, use fonts-noto instead
  if [ "$ISON1604" = "y" ]; then
    sudo apt-get $APTVERBOSITY install ttf-mscorefonts-installer fonts-noto fontconfig libcups2 libfontconfig1 libglu1-mesa libice6 libsm6 libxinerama1 libxrender1 libxt6
  else
    sudo apt-get $APTVERBOSITY install ttf-mscorefonts-installer fonts-droid fontconfig libcups2 libfontconfig1 libglu1-mesa libice6 libsm6 libxinerama1 libxrender1 libxt6
  fi
  echo
  echogreen "Finished installing LibreOffice"
  echo
else
  echo
  echo "Skipping install of LibreOffice"
  echored "If you install LibreOffice/OpenOffice separetely, remember to update alfresco-global.properties"
  echored "Also run: sudo apt-get install ttf-mscorefonts-installer fonts-droid libxinerama1"
  echo
fi

# Check if tomcat has been installed in which alfresco configuration should be created
if [ -d "$CATALINA_HOME" ]; then
	caching_found=$(grep -o "caching" $CATALINA_HOME/conf/context.xml | wc -l)
	if [ $caching_found = 0 ]; then
		# Increase cache to support alfresco static resources
		sudo sed -i '/<\/Context>/i \
		<Resources	\
			cachingAllowed="true"	\
			cacheMaxSize="102400"	\
			cacheObjectMaxSize="1536" \/> ' $CATALINA_HOME/conf/context.xml
	fi
	
	# Insert classes and libs need to be loaded during startup
	sudo sed -i 's/\(^shared\.loader=\).*/\1"\$\{catalina\.base\}\/shared\/classes","\$\{catalina\.base\}\/shared\/lib\/\*\.jar"/' $CATALINA_HOME/conf/catalina.properties
	
	# Check if camunda exists in current server.xml (camunda has been installed in previous step)
	camunda_found=$(grep -o "camunda" $CATALINA_HOME/conf/server.xml | wc -l)
		
	##
	# TODO, alfresco and camunda are using the same tomcat server configuration file, we need to find a way to insert alfresco
	# configuration into existing one without overwite the existing file and re-insert camunda config
	##
	# Copy alfresco tomcat server.xml
	sudo rsync -avz $BASE_INSTALL/tomcat/server.xml $CATALINA_HOME/conf/
	sudo sed -i "s/@@ALF_DATA_HOME@@/$ALF_DATA_HOME_PATH/g" $CATALINA_HOME/conf/server.xml
	
	# Create /shared
	sudo mkdir -p $CATALINA_HOME/shared/classes/alfresco/extension
	sudo mkdir -p $CATALINA_HOME/shared/classes/alfresco/web-extension
	sudo mkdir -p $CATALINA_HOME/shared/lib
	
	# Add endorsed dir
	sudo mkdir -p $CATALINA_HOME/endorsed

	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to add the dns name, port and protocol for your server(s)."
	echo "It is important that this is is a resolvable server name."
	echo "This information will be added to default configuration files."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	
	# Get alfresco port in domain table
	alfresco_line=$(grep "alfresco" $BASE_INSTALL/domain.txt)
	IFS='|' read -ra arr <<<"$alfresco_line"
	alfresco_port="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	SHARE_HOSTNAME="$(echo -e "${arr[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	
	if [ -z "$SHARE_HOSTNAME" ]; then
		read -e -p "Please enter the public host name for Share server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" SHARE_HOSTNAME
	fi
	
	
	if [ -f "$NGINX_CONF/sites-available/$SHARE_HOSTNAME.conf" ]; then
		# Remove old configuration
		rm $NGINX_CONF/sites-available/$SHARE_HOSTNAME.conf
	fi
	
	
	read -e -p "Please enter the protocol to use for public Share server (http or https)${ques} [http] " -i "http" SHARE_PROTOCOL
	
	SHARE_PORT=80
	if [ "${SHARE_PROTOCOL,,}" = "https" ]; then
		SHARE_PORT=443
		# Create a new one to remove common snippet
		if [ -n "$TOMCAT_HTTP_PORT" ]; then
		  if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
			. $BASE_INSTALL/scripts/ssl.sh	$SHARE_HOSTNAME
		  else
			. scripts/ssl.sh $SHARE_HOSTNAME
		  fi
		else
			if [ -f "$BASE_INSTALL/scripts/ssl.sh" ]; then
			. $BASE_INSTALL/scripts/ssl.sh	$SHARE_HOSTNAME
		  else
			. scripts/ssl.sh $SHARE_HOSTNAME
		  fi
		fi
	fi
	read -e -p "Please enter the host name for Alfresco Repository server (fully qualified domain name) as shown to users${ques} [$SHARE_HOSTNAME] " -i "$SHARE_HOSTNAME" REPO_HOSTNAME
	read -e -p "Please enter the host name for Alfresco Repository server that Share will use to talk to repository${ques} [localhost] " -i "localhost" SHARE_TO_REPO_HOSTNAME

	
	# Add default alfresco-global.propertis
	ALFRESCO_GLOBAL_TMP_PATH=$TMP_INSTALL
	ALFRESCO_GLOBAL_PROPERTIES=$ALFRESCO_GLOBAL_TMP_PATH/alfresco-global.properties
	
	sudo rsync -avz $BASE_INSTALL/tomcat/alfresco-global.properties $ALFRESCO_GLOBAL_TMP_PATH
	sudo sed -i "s/@@ALFRESCO_SHARE_SERVER@@/$SHARE_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/@@ALFRESCO_SHARE_SERVER_PORT@@/$SHARE_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/@@ALFRESCO_SHARE_SERVER_PROTOCOL@@/$SHARE_PROTOCOL/g" $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/@@ALFRESCO_REPO_SERVER@@/$REPO_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
	
	sudo sed -i "s/@@ALF_DATA_HOME@@/$ALF_DATA_HOME_PATH/g" $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/@@ALF_HOME@@/$ALFRESCO_HOME_PATH/g" $ALFRESCO_GLOBAL_PROPERTIES
	
	# Replace database configuration, use default value if variable is not set (in case of running this script independently)
	if [ -n "$ALFRESCO_USER" ]; then
		sudo sed -i "s/@@DB_USERNAME@@/$ALFRESCO_USER/g"		$ALFRESCO_GLOBAL_PROPERTIES  
		sudo sed -i "s/@@DB_PASSWORD@@/$ALFRESCO_PASSWORD/g" $ALFRESCO_GLOBAL_PROPERTIES
	else
		sudo sed -i "s/@@DB_USERNAME@@/$ALF_DB_USERNAME_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES  
		sudo sed -i "s/@@DB_PASSWORD@@/$ALF_DB_PASSWORD_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
	fi
	
	if [ $DB_SELECTION = 'MA' ] || [ $DB_SELECTION = 'MY' ] ; then	#mysql
		sudo sed -i "s/@@DB_DRIVER@@/$MYSQL_DB_DRIVER_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
		sudo sed -i "s/@@DB_PORT@@/$MYSQL_DB_PORT_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
		sudo sed -i "s/@@DB_CONNECTOR@@/$MYSQL_DB_CONNECTOR_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
		sudo sed -i "s/@@DB_SUFFIX@@/$MYSQL_DB_SUFFIX_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
	else	#postgres
		sudo sed -i "s/@@DB_DRIVER@@/$ALF_DB_DRIVER_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
		sudo sed -i "s/@@DB_PORT@@/$ALF_DB_PORT_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
		sudo sed -i "s/@@DB_CONNECTOR@@/$ALF_DB_CONNECTOR_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
		sudo sed -i "s/@@DB_SUFFIX@@/$ALF_DB_SUFFIX_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
	fi
	
	# OPENCMIS
	sudo sed -i "s/\(^opencmis.context.override=\).*/\1true/"  $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/\(^opencmis.context.value=\).*/\1/"  $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/\(^opencmis.servletpath.override=\).*/\1true/"  $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/\(^opencmis.servletpath.value=\).*/\1/"  $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/\(^opencmis.server.override=\).*/\1true/"  $ALFRESCO_GLOBAL_PROPERTIES
	sudo sed -i "s/\(^opencmis.server.value=\).*/\1${SHARE_PROTOCOL,,}:\/\/$SHARE_HOSTNAME\/alfresco\/api/"  $ALFRESCO_GLOBAL_PROPERTIES
	
	if [ -n "$ALFRESCO_DB" ]; then
		sudo sed -i "s/@@DB_NAME@@/$ALFRESCO_DB/g" $ALFRESCO_GLOBAL_PROPERTIES
	else
		sudo sed -i "s/@@DB_NAME@@/$ALF_DB_NAME_DEFAULT/g" $ALFRESCO_GLOBAL_PROPERTIES
	fi
	
	if [ -n "$alfresco_port" ]; then
		TOMCAT_HTTP_PORT=$alfresco_port
	fi
	
	# Check if tomcat ports have been changed previously, 
	# so we will roll back to original state when server.xml is overwritten after installing alfresco 
	if [ -n "$TOMCAT_HTTP_PORT" ]; then
		# Change server default port
		sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/8005/$TOMCAT_SHUTDOWN_PORT/g" $CATALINA_HOME/conf/server.xml
		sudo sed -i "s/8009/$TOMCAT_AJP_PORT/g" $CATALINA_HOME/conf/server.xml
	else
		TOMCAT_HTTP_PORT=8080;
	fi
  
	#Enable smart folder funtionality
	sudo sed -i "s/@@SF_ENABLE@@/$SF_ENABLE/g" $ALFRESCO_GLOBAL_PROPERTIES
	
	# Change default port (8080)
	sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g"  $ALFRESCO_GLOBAL_PROPERTIES
  
	sudo mv $ALFRESCO_GLOBAL_PROPERTIES $CATALINA_HOME/shared/classes/
  

	read -e -p "Install Share config file (recommended)${ques} [y/n] " -i "$DEFAULTYESNO" installshareconfig
	if [ "$installshareconfig" = "y" ]; then
		SHARE_CONFIG_CUSTOM_TMP_PATH=$TMP_INSTALL
		SHARE_CONFIG_CUSTOM=$SHARE_CONFIG_CUSTOM_TMP_PATH/share-config-custom.xml
		sudo rsync -avz $BASE_INSTALL/tomcat/share-config-custom.xml $SHARE_CONFIG_CUSTOM_TMP_PATH
		sudo sed -i "s/@@ALFRESCO_SHARE_SERVER@@/$SHARE_HOSTNAME/g" $SHARE_CONFIG_CUSTOM
		sudo sed -i "s/@@SHARE_TO_REPO_SERVER@@/$SHARE_TO_REPO_HOSTNAME/g" $SHARE_CONFIG_CUSTOM
		sudo sed -i "s/8080/$TOMCAT_HTTP_PORT/g"  $SHARE_CONFIG_CUSTOM
		sudo mv $SHARE_CONFIG_CUSTOM $CATALINA_HOME/shared/classes/alfresco/web-extension/
	fi
  
	echo "Installing configuration for alfresco on nginx..."
	
	# We use http if there is no https config in nginx
	if [ ! -f "/etc/nginx/sites-available/$SHARE_HOSTNAME.conf" ]; then
		sudo rsync -avz $NGINX_CONF/sites-available/domain.conf /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		sudo ln -s /etc/nginx/sites-available/$SHARE_HOSTNAME.conf /etc/nginx/sites-enabled/
	  
		sudo sed -i "s/@@DNS_DOMAIN@@/$SHARE_HOSTNAME/g" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		
	fi
	
	# Check if camunda config exists in tomcat server.xml
	alfresco_found=$(grep -o "share" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf | wc -l)

	if [ $alfresco_found = 0 ]; then
		# Insert cache config
		sudo sed -i '1 i\proxy_cache_path \/var\/cache\/nginx\/alfresco levels=1 keys_zone=alfrescocache:256m max_size=512m inactive=1440m;\n' /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		
		sudo sed -i "0,/server/s/server/upstream alfresco {	\n\tserver localhost\:$TOMCAT_HTTP_PORT;	\n}	\n\n upstream share {    \n\tserver localhost:$TOMCAT_HTTP_PORT;	\n}\n\n&/" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		
		sudo sed -i "s/##REWRITE##/rewrite \^\/\$	\/share;/g" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		
		# Insert alfresco configuration content before the last line in domain.conf in nginx
		#sudo sed -i "$e cat $NGINX_CONF/sites-available/alfresco.conf" /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		sudo mkdir temp
		sudo cp $NGINX_CONF/sites-available/alfresco.snippet	temp/
		sudo sed -e '/##ALFRESCO##/ {' -e 'r temp/alfresco.snippet' -e 'd' -e '}' -i /etc/nginx/sites-available/$SHARE_HOSTNAME.conf
		sudo rm -rf temp
		
		sudo mkdir -p /var/cache/nginx/alfresco

		sudo chown -R www-data:root /var/cache/nginx/alfresco
	fi

fi	

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install ImageMagick."
echo "This will ImageMagick from Ubuntu packages."
echo "It is recommended that you install ImageMagick."
echo "If you prefer some other way of installing ImageMagick, skip this step."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install ImageMagick${ques} [y/n] " -i "$DEFAULTYESNO" installimagemagick
if [ "$installimagemagick" = "y" ]; then
	echoblue "Installing ImageMagick. Fetching packages..."
	sudo apt-get $APTVERBOSITY install imagemagick ghostscript libgs-dev libjpeg62 libpng3
	echo
	if [ "$ISON1604" = "y" ]; then
		echoblue "Creating symbolic link for ImageMagick-6."
		sudo ln -s /etc/ImageMagick-6 /etc/ImageMagick
	fi
	
	echo
	echogreen "Finished installing ImageMagick"
	echo
else
	echo
	echo "Skipping install of ImageMagick"
	echored "Remember to install ImageMagick later. It is needed for thumbnail transformations."
	echo
fi

echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Patching ImageMagick for CVE-2016–3714."
echo "This is all automatic if present."
echo "More info at https://imagetragick.com/"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

###16.04 already Patched
if [ "$ISON1604" = "n" ]; then
	IMAGEMAGICKPOLICYFILE="/etc/ImageMagick/policy.xml"

	if [ -f "$IMAGEMAGICKPOLICYFILE" ]; then
		if grep -q "rights=\"none\" pattern=\"EPHEMERAL\"" "$IMAGEMAGICKPOLICYFILE"; then
			echogreen "The policy file looks like it already contains the patch: $IMAGEMAGICKPOLICYFILE"
		else 
			sudo sed -i '/<policymap>/a \
			  <policy domain="coder" rights="none" pattern="EPHEMERAL" /> \
			  <policy domain="coder" rights="none" pattern="URL" /> \
			  <policy domain="coder" rights="none" pattern="HTTPS" /> \
			  <policy domain="coder" rights="none" pattern="MVG" /> \
			  <policy domain="coder" rights="none" pattern="MSL" /> \
			  <policy domain="coder" rights="none" pattern="TEXT" /> \
			  <policy domain="coder" rights="none" pattern="SHOW" /> \
			  <policy domain="coder" rights="none" pattern="WIN" /> \
			  <policy domain="coder" rights="none" pattern="PLT" />' $IMAGEMAGICKPOLICYFILE
          
			echogreen "Patched file: $IMAGEMAGICKPOLICYFILE" 
		fi
	else
		echored "Could not find file to patch: $IMAGEMAGICKPOLICYFILE"
	fi
fi

echo
echoblue "Adding basic support files. Always installed if not present."
echo
	
# Always add the addons dir and scripts
sudo mkdir -p $DEVOPS_HOME/addons/war
sudo mkdir -p $DEVOPS_HOME/addons/share
sudo mkdir -p $DEVOPS_HOME/addons/alfresco
	
if [ ! -f "$DEVOPS_HOME/addons/apply.sh" ]; then
	echo "Downloading apply.sh script..."
	sudo rsync -avz $BASE_INSTALL/scripts/apply.sh $DEVOPS_HOME/addons/
	sudo chmod u+x $DEVOPS_HOME/addons/apply.sh
fi
	
if [ ! -f "$DEVOPS_HOME/addons/alfresco-mmt.jar" ]; then
	sudo curl -# -o $DEVOPS_HOME/addons/alfresco-mmt.jar $ALFMMTJAR
fi

# Add the jar modules dir
sudo mkdir -p $DEVOPS_HOME/modules/platform
sudo mkdir -p $DEVOPS_HOME/modules/share

sudo mkdir -p $DEVOPS_HOME/bin
if [ ! -f "$DEVOPS_HOME/bin/alfresco-pdf-renderer" ]; then
	echo "Downloading Alfresco PDF Renderer binary alfresco-pdf-renderer..."
    sudo curl -# -o $TMP_INSTALL/alfresco-pdf-renderer.tgz $ALFRESCO_PDF_RENDERER
    sudo tar -xf $TMP_INSTALL/alfresco-pdf-renderer.tgz -C $TMP_INSTALL
    sudo mv $TMP_INSTALL/alfresco-pdf-renderer $DEVOPS_HOME/bin/
fi

sudo mkdir -p $DEVOPS_HOME/scripts
if [ ! -f "$DEVOPS_HOME/scripts/mariadb.sh" ]; then
    echo "Copying mariadb.sh install and setup script..."
	sudo rsync -avz $BASE_INSTALL/scripts/mariadb.sh $DEVOPS_HOME/scripts/
fi

if [ ! -f "$DEVOPS_HOME/scripts/postgresql.sh" ]; then
    echo "Copying postgresql.sh install and setup script..."
	sudo rsync -avz $BASE_INSTALL/scripts/postgresql.sh $DEVOPS_HOME/scripts/
fi

if [ ! -f "$DEVOPS_HOME/scripts/mysql.sh" ]; then
    echo "Copying mysql.sh install and setup script..."
	sudo rsync -avz $BASE_INSTALL/scripts/mysql.sh $DEVOPS_HOME/scripts/
fi

if [ ! -f "$DEVOPS_HOME/scripts/limitconvert.sh" ]; then
    echo "Copying limitconvert.sh script..."
	sudo rsync -avz $BASE_INSTALL/scripts/limitconvert.sh $DEVOPS_HOME/scripts/
fi

# if [ ! -f "$DEVOPS_HOME/scripts/createssl.sh" ]; then
#     echo "Copying createssl.sh script..."
# 	sudo rsync -avz $BASE_INSTALL/scripts/createssl.sh $DEVOPS_HOME/scripts/
#  fi
 
if [ ! -f "$DEVOPS_HOME/scripts/libreoffice.sh" ]; then
    echo "Copying libreoffice.sh script..."
	sudo rsync -avz $BASE_INSTALL/scripts/libreoffice.sh $DEVOPS_HOME/scripts/
    sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $DEVOPS_HOME/scripts/libreoffice.sh
fi

 if [ ! -f "$DEVOPS_HOME/scripts/iptables.sh" ]; then
    echo "Copying iptables.sh script..."
	sudo rsync -avz $BASE_INSTALL/scripts/iptables.sh $DEVOPS_HOME/scripts/
fi

if [ ! -f "$DEVOPS_HOME/scripts/alfresco-iptables.conf" ]; then
    echo "Copying alfresco-iptables.conf upstart script..."
	sudo rsync -avz $BASE_INSTALL/scripts/alfresco-iptables.conf $DEVOPS_HOME/scripts/
fi

if [ ! -f "$DEVOPS_HOME/scripts/ams.sh" ]; then
    echo "Copying maintenance shutdown script..."
	sudo rsync -avz $BASE_INSTALL/scripts/ams.sh $DEVOPS_HOME/scripts/
fi

sudo chmod 755 $DEVOPS_HOME/scripts/*.sh

# Keystore
sudo mkdir -p $ALF_DATA_HOME/keystore

# Only check for precesence of one file, assume all the rest exists as well if so.
if [ ! -f " $ALF_DATA_HOME/keystore/ssl.keystore" ]; then
    echo "Downloading keystore files..."
    sudo curl -# -o $ALF_DATA_HOME/keystore/browser.p12 $KEYSTOREBASE/browser.p12
    sudo curl -# -o $ALF_DATA_HOME/keystore/generate_keystores.sh $KEYSTOREBASE/generate_keystores.sh
    sudo curl -# -o $ALF_DATA_HOME/keystore/keystore $KEYSTOREBASE/keystore
    sudo curl -# -o $ALF_DATA_HOME/keystore/keystore-passwords.properties $KEYSTOREBASE/keystore-passwords.properties
    sudo curl -# -o $ALF_DATA_HOME/keystore/ssl-keystore-passwords.properties $KEYSTOREBASE/ssl-keystore-passwords.properties
    sudo curl -# -o $ALF_DATA_HOME/keystore/ssl-truststore-passwords.properties $KEYSTOREBASE/ssl-truststore-passwords.properties
    sudo curl -# -o $ALF_DATA_HOME/keystore/ssl.keystore $KEYSTOREBASE/ssl.keystore
    sudo curl -# -o $ALF_DATA_HOME/keystore/ssl.truststore $KEYSTOREBASE/ssl.truststore
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Alfresco war files."
echo "Download war files and optional addons."
echo "If you have already downloaded your war files you can skip this step and add "
echo "them manually."
echo
echo "If you use separate Alfresco and Share server, only install the needed for each"
echo "server. Alfresco Repository will need Share Services if you use Share."
echo
echo "This install place downloaded files in the $DEVOPS_HOME/addons and then use the"
echo "apply.sh script to add them to tomcat/webapps. Se this script for more info."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add Alfresco Repository war file${ques} [y/n] " -i "$DEFAULTYESNO" installwar
if [ "$installwar" = "y" ]; then

  if [ ! -f "$TMP_INSTALL/alfresco.war" ]; then
	echo "Downloading alfresco.war..."
	sudo curl -# -o $TMP_INSTALL/alfresco.war $ALFREPOWAR
  fi	
  sudo rsync -avz $TMP_INSTALL/alfresco.war	$DEVOPS_HOME/addons/war/
  #sudo curl -# -o $DEVOPS_HOME/addons/war/alfresco.war $ALFREPOWAR
  echo

  # Add default alfresco and share modules classloader config files
  #sudo curl -# -o $CATALINA_HOME/conf/Catalina/localhost/alfresco.xml $BASE_INSTALL/tomcat/alfresco.xml
  sudo rsync -avz $BASE_INSTALL/tomcat/alfresco.xml $CATALINA_HOME/conf/Catalina/localhost/

  echogreen "Finished adding Alfresco Repository war file"
  echo
else
  echo
  echo "Skipping adding Alfresco Repository war file and addons"
  echo
fi

read -e -p "Add Share Client war file${ques} [y/n] " -i "$DEFAULTYESNO" installsharewar
if [ "$installsharewar" = "y" ]; then

  if [ ! -f "$TMP_INSTALL/share.war" ]; then
	echo "Downloading share.war..."
	sudo curl -# -o $TMP_INSTALL/share.war $ALFSHAREWAR
  fi	
  sudo rsync -avz $TMP_INSTALL/share.war	$DEVOPS_HOME/addons/war/

  echogreen "Downloading Share war file..."
  #sudo curl -# -o $DEVOPS_HOME/addons/war/share.war $ALFSHAREWAR
  sudo rsync -avz $TMP_INSTALL/share.war	$DEVOPS_HOME/addons/war/

  # Add default alfresco and share modules classloader config files
  #sudo curl -# -o $CATALINA_HOME/conf/Catalina/localhost/share.xml $BASE_INSTALL/tomcat/share.xml
  sudo rsync -avz $BASE_INSTALL/tomcat/share.xml $CATALINA_HOME/conf/Catalina/localhost/

  echo
  echogreen "Finished adding Share war file"
  echo
else
  echo
  echo "Skipping adding Alfresco Share war file"
  echo
fi

if [ "$installwar" = "y" ] || [ "$installsharewar" = "y" ]; then
cd $TMP_INSTALL

if [ "$installwar" = "y" ]; then
    echored "You must install Share Services if you intend to use Share Client."
    read -e -p "Add Share Services plugin${ques} [y/n] " -i "$DEFAULTYESNO" installshareservices
    if [ "$installshareservices" = "y" ]; then
      echo "Downloading Share Services addon..."
      curl -# -O $ALFSHARESERVICES
      sudo mv alfresco-share-services*.amp $DEVOPS_HOME/addons/alfresco/
    fi
fi

read -e -p "Add Google docs integration${ques} [y/n] " -i "$DEFAULTYESNO" installgoogledocs
if [ "$installgoogledocs" = "y" ]; then
  echo "Downloading Google docs addon..."
  if [ "$installwar" = "y" ]; then
    curl -# -O $GOOGLEDOCSREPO
    sudo mv alfresco-googledocs-repo*.amp $DEVOPS_HOME/addons/alfresco/
  fi
  if [ "$installsharewar" = "y" ]; then
    curl -# -O $GOOGLEDOCSSHARE
    sudo mv alfresco-googledocs-share* $DEVOPS_HOME/addons/share/
  fi
fi
fi


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Alfresco Office Services (Sharepoint protocol emulation)."
echo "This allows you to open and save Microsoft Office documents online."
echored "This module is not Open Source (Alfresco proprietary)."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Alfresco Office Services integration${ques} [y/n] " -i "$DEFAULTYESNO" installssharepoint
if [ "$installssharepoint" = "y" ]; then
    echogreen "Installing Alfresco Offices Services bundle..."
    echogreen "Downloading Alfresco Office Services amp file"
    # Sub shell to keep the file name
    (cd $DEVOPS_HOME/addons/alfresco;sudo curl -# -O $AOS_AMP)
    echogreen "Downloading _vti_bin.war into tomcat/webapps"
    sudo curl -# -o $DEVOPS_HOME/tomcat/webapps/_vti_bin.war $AOS_VTI
    echogreen "Downloading ROOT.war into tomcat/webapps"
    sudo curl -# -o $DEVOPS_HOME/tomcat/webapps/ROOT.war $AOS_SERVER_ROOT
fi

# Install of war and addons complete, apply them to war file
if [ "$installwar" = "y" ] || [ "$installsharewar" = "y" ] || [ "$installssharepoint" = "y" ]; then
    # Check if Java is installed before trying to apply
    if type -p java; then
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        _java="$JAVA_HOME/bin/java"
        echored "No JDK installed. When you have installed JDK, run "
        echored "$DEVOPS_HOME/addons/apply.sh all"
        echored "to install addons with Alfresco or Share."
    fi
    if [[ "$_java" ]]; then
        sudo $DEVOPS_HOME/addons/apply.sh all
    fi
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Solr4 indexing engine."
echo "You can run Solr4 on a separate server, unless you plan to do that you should"
echo "install the Solr4 indexing engine on the same server as your repository server."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Solr4 indexing engine${ques} [y/n] " -i "$DEFAULTYESNO" installsolr
if [ "$installsolr" = "y" ]; then

  # Make sure we have unzip available
  sudo apt-get $APTVERBOSITY install unzip

  # Check if we have an old install
  if [ -d "$DEVOPS_HOME/solr4" ]; then
     sudo mv $DEVOPS_HOME/solr4 $DEVOPS_HOME/solr4_BACKUP_`eval date +%Y%m%d%H%M`
  fi
  sudo mkdir -p $DEVOPS_HOME/solr4
  cd $DEVOPS_HOME/solr4
  
  if [ ! -f "$TMP_INSTALL/solr4.war" ]; then
	echo "Downloading solr4.war..."
	sudo curl -# -o $TMP_INSTALL/solr4.war	$SOLR4_WAR_DOWNLOAD
  fi	
  sudo rsync -avz $TMP_INSTALL/solr4.war	$CATALINA_HOME/webapps/


  echogreen "Downloading solr4.war file..."
  #sudo curl -# -o $CATALINA_HOME/webapps/solr4.war $SOLR4_WAR_DOWNLOAD

  echogreen "Copying config file..."
  #sudo curl -# -o $DEVOPS_HOME/solr4/solrconfig.zip $SOLR4_CONFIG
  sudo rsync -avz $SOLR4_CONFIG $DEVOPS_HOME/solr4
  
  echogreen "Expanding config file..."
  #sudo unzip -q solrconfig.zip
  sudo unzip -q $DEVOPS_HOME/solr4/$SOLR4_CONFIG_FILE -d $DEVOPS_HOME/solr4/
  
  sudo rm $DEVOPS_HOME/solr4/$SOLR4_CONFIG_FILE

  echogreen "Configuring..."

  # Make sure dir exist
  sudo mkdir -p $ALF_DATA_HOME/solr4
  mkdir -p $TMP_INSTALL

  # Remove old config if exists
  if [ -f "$CATALINA_HOME/conf/Catalina/localhost/solr.xml" ]; then
     sudo rm $CATALINA_HOME/conf/Catalina/localhost/solr.xml
  fi

  # Set the solr data path
  SOLRDATAPATH="$ALF_DATA_HOME/solr4"
  # Escape for sed
  SOLRDATAPATH="${SOLRDATAPATH//\//\\/}"
  DEVOPS_HOME_PATH="${DEVOPS_HOME//\//\\/}"

  sudo mv $DEVOPS_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties $DEVOPS_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties.orig
  sudo mv $DEVOPS_HOME/solr4/archive-SpacesStore/conf/solrcore.properties $DEVOPS_HOME/solr4/archive-SpacesStore/conf/solrcore.properties.orig
  sudo sed "s/@@ALFRESCO_SOLR4_DATA_DIR@@/$SOLRDATAPATH/g" $DEVOPS_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties.orig >  $TMP_INSTALL/solrcore.properties
  sudo mv  $TMP_INSTALL/solrcore.properties $DEVOPS_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties
  sudo sed "s/@@ALFRESCO_SOLR4_DATA_DIR@@/$SOLRDATAPATH/g" $DEVOPS_HOME/solr4/archive-SpacesStore/conf/solrcore.properties.orig >  $TMP_INSTALL/solrcore.properties
  sudo mv  $TMP_INSTALL/solrcore.properties $DEVOPS_HOME/solr4/archive-SpacesStore/conf/solrcore.properties

  echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $TMP_INSTALL/solr4.xml
  echo "<Context debug=\"0\" crossContext=\"true\">" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/home\" type=\"java.lang.String\" value=\"$DEVOPS_HOME/solr4\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/model/dir\" type=\"java.lang.String\" value=\"$DEVOPS_HOME/solr4/alfrescoModels\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/content/dir\" type=\"java.lang.String\" value=\"$ALF_DATA_HOME/solr4/content\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "</Context>" >> $TMP_INSTALL/solr4.xml
  sudo mv $TMP_INSTALL/solr4.xml $CATALINA_HOME/conf/Catalina/localhost/solr4.xml
  
  sudo sed -i "s/@@ALFRESCO_SOLR4_DIR@@/$DEVOPS_HOME_PATH\/solr4/g" $DEVOPS_HOME/solr4/context.xml  
  sudo sed -i "s/@@ALFRESCO_SOLR4_MODEL_DIR@@/$ALF_DATA_HOME_PATH\/solr4\/model/g" $DEVOPS_HOME/solr4/context.xml 
  sudo sed -i "s/@@ALFRESCO_SOLR4_CONTENT_DIR@@/$ALF_DATA_HOME_PATH\/solr4\/content/g" $DEVOPS_HOME/solr4/context.xml
  
  
  if [ ! -f "$CATALINA_HOME/conf/Catalina/localhost/solr4.xml" ]; then
	sudo mv $DEVOPS_HOME/solr4/context.xml $CATALINA_HOME/conf/Catalina/localhost/solr4.xml
  fi

  echo
  echogreen "Finished installing Solr4 engine."
  echored "Verify your setting in alfresco-global.properties."
  echo "Set property value index.subsystem.name=solr4"
  echo
else
  echo
  echo "Skipping installing Solr4."
  echo "You can always install Solr4 at a later time."
  echo
fi



