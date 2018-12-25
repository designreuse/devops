# Install Magento2 -Ubuntu 16.04  LST

### Installation
Step 1: Install the Nginx WebServer
```sh
$ sudo apt-get update
$ sudo apt-get install nginx -y
```
Verify that nginx has been installed properly by checking the port
```sh
$ netstat -plntu | grep 80
```

Step 2 - Install and Configure PHP-FPM
```sh
$ sudo apt-get install php7.1-fpm php7.1-mcrypt php7.1-curl php7.1-cli php7.1-mysql php7.1-gd php7.1-xsl php7.1-json php7.1-intl php-pear php7.1-dev php7.1-common php7.1-mbstring php7.1-zip php-soap libcurl3 curl -y
```
confid php-fpm file /etc/php/7.0/fpm/php.ini
```sh
$ memory_limit = 1024M
$ max_execution_time = 1800
$ zlib.output_compression = On
```
Restart FPM
```sh
$ sudo systemctl restart php7.1-fpm
```

Step 3 - Installing Percona Server Mysql 5.7 from Percona apt repository
```sh
$ wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
$ sudo dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
$ sudo apt-get update
$ sudo apt-get install percona-server-server-5.7
(setup pwd for root user)
```

Step 4: Install Composer
```sh
$ curl -sS https://getcomposer.org/installer | php
// Install Composer Globally
$  sudo mv composer.phar /usr/local/bin/composer
```

Step 5: Get Magento 2 Source

```sh
$ sudo composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:<version> your_root_folder
Example:
$ cd /var/www/m2 
$ sudo composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:2.2.3 m223
When prompted, enter your authentication keys. Please refer http://devdocs.magento.com/guides/v2.0/install-gde/prereq/connect-auth.html
```
Step 6: Install Magento via command line

```sh
$ php bin/magento setup:install --base-url=<YOUR_WEBSITE_URL> --backend-frontname=admin --db-host=127.0.0.1 --db-name=<DB_NAME> --db-password=<DB_PWD> --db-user=<DB_USER> --admin-firstname=Tri --admin-lastname=Nguyen --admin-email=ntri@tctav.com --admin-user=admin --admin-password=test123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1
```

Step 7: Create Nginx configuration file
```sh
$ cd /etc/nginx/sites-available
$ sudo vi magento
Paste The content below:

upstream fastcgi_backend {
     server  unix:/run/php/php7.1-fpm.sock;
 }

 server {
     listen 80;
     server_name YOUR_WEBSITE_URL;
     set $MAGE_ROOT YOUR_ROOT_PROJECT_FOLDER;
     include YOUR_ROOT_PROJECT_FOLDER/nginx.conf.sample;
 }
 
$ sudo systemctl restart nginx
```
FINISH