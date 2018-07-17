## 1.1.ubuntu-upgrade.sh

```
## cd /home/ubuntu/
git clone https://github.com/o2oprotocol/DevOps.git       && 
cd DevOps
```

### Ubuntu update & upgrade

```
sudo apt-get -qq -y update && sudo apt-get -qq -y upgrade &&
sudo apt-get -qq -y install zip unzip                     &&
sudo timedatectl set-timezone Asia/Ho_Chi_Minh            &&

sudo fallocate -l 8G /swapfile    &&
sudo chmod 600 /swapfile          &&
sudo mkswap /swapfile             &&
sudo swapon /swapfile             &&
sudo cp /etc/fstab /etc/fstab.bak &&
echo "/swapfile none swap defaults 0 0" | sudo tee --append /etc/fstab       &&
sudo echo "vm.swappiness=20"            | sudo tee --append /etc/sysctl.conf &&
echo "vm.vfs_cache_pressure=60"         | sudo tee --append /etc/sysctl.conf &&
sudo locale-gen en_US.utf8
```

## 1.2.install-MEAN.sh

### Install NGNIX

```
sudo apt-get -qq -y update && sudo apt-get -qq -y install nginx &&
systemctl status nginx                                          &&
sudo systemctl enable nginx                                     &&

sudo ufw allow 'Nginx HTTP'  &&
sudo ufw allow 'Nginx HTTPS' &&
sudo ufw allow 'OpenSSH'     &&
sudo ufw allow 8080          &&
sudo ufw allow 8888          &&
sudo ufw enable              
```

### Install NVM and Node.JS

```
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash &&
export NVM_DIR="$HOME/.nvm" && \. "$NVM_DIR/nvm.sh"
# close and reopen the terminal: $ `nvm --version && nvm ls`
# v6.10.3 for AWS Lambda & Node 8.x
nvm install v6.10.3   &&
nvm use 6.10.3		&&
npm install -g npm@latest &&
npm install -g serverless &&
npm install -g pm2        &&
pm2 startup systemd
```

```MacOS
touch ~/.bash_profile
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash

nvm install v8.10.0 &&
nvm alias default 8.10.0
```

### Install Redis

```
sudo apt-get -qq -y install redis-server                           &&
echo "maxmemory 1024mb" | sudo tee --append /etc/redis/redis.conf  &&
echo "maxmemory-policy allkeys-lru" | sudo tee --append /etc/redis/redis.conf &&
sudo systemctl enable redis-server.service
```

### Install MongoDB

```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6  &&
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list &&
sudo apt-get -qq -y update                 && 
sudo apt-get -qq -y install -y mongodb-org &&
sudo systemctl enable mongod
```

### Install Certbot SSL

```
sudo add-apt-repository ppa:certbot/certbot &&
sudo apt-get -qq -y update && sudo apt-get -qq -y install python-certbot-nginx 
```

## SSL

```
sudo rsync -avz /home/ubuntu/DevOps/_ubuntu/etc/nginx/snippets/ /etc/nginx/snippets/

sudo certbot certonly --authenticator standalone --installer nginx -d devops-serverless.o2oprotocol.io --email o2oprotocol101@gmail.com --pre-hook "sudo service nginx stop" --post-hook "sudo service nginx start" &&
sudo rsync -avz /home/ubuntu/DevOps/_ubuntu/etc/nginx/sites-available/domainSSL /etc/nginx/sites-available/devops-serverless.o2oprotocol.io.conf &&
sudo ln -s /etc/nginx/sites-available/devops-serverless.o2oprotocol.io.conf /etc/nginx/sites-enabled/                                            &&
sudo sed -i "s/@@DNS_DOMAIN@@/devops-serverless.o2oprotocol.io/g" /etc/nginx/sites-available/devops-serverless.o2oprotocol.io.conf                           &&
sudo sed -i "s/@@PORT@@/5000/g" /etc/nginx/sites-available/devops-serverless.o2oprotocol.io.conf                                                      && 
sudo service nginx reload
```

## 1.3.install-Java-Tomcat.sh

### Install Oracle Java SDK 8 + Ant + Maven

```
sudo apt-get -qq -y install python-software-properties software-properties-common &&
sudo add-apt-repository ppa:webupd8team/java                                      &&
sudo apt-get -qq -y update                                                        &&
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections &&
sudo apt-get -qq -y install oracle-java8-installer                                &&
sudo update-java-alternatives -s java-8-oracle                                    &&
sudo apt-get -qq -y update && sudo apt-get -qq -y install maven                   &&
sudo apt-get -qq -y update && sudo apt-get -qq -y install ant                     
```

### DevOps User/Group

`sudo adduser --system --disabled-login --disabled-password --group devops`

### Install Tomcat 8.x

```
curl -# -L -O http://mirrors.viethosting.com/apache/tomcat/tomcat-8/v8.5.29/bin/apache-tomcat-8.5.29.tar.gz &&
tar xf apache-tomcat-8.5.29.tar.gz &&
mv apache-tomcat-8.5.29 tomcat     &&
sudo mkdir -p /home/devops/tomcat  &&
sudo mv tomcat /home/devops/       &&
rm -rf /home/devops/tomcat/webapps/{docs,examples}         &&
sed -i "s/8080/8888/g" /home/devops/tomcat/conf/server.xml &&
sed -i "s/8005/8885/g" /home/devops/tomcat/conf/server.xml &&
sed -i "s/8009/8889/g" /home/devops/tomcat/conf/server.xml &&
sed -i "s/443/8443/g"  /home/devops/tomcat/conf/server.xml &&
                                       
sudo mkdir -p /home/devops/logs                                                     &&
sudo chown -R devops:devops /home/devops/tomcat/{webapps,temp,logs,work,conf,lib}   &&
sudo chmod -R 770 /home/devops/tomcat/{webapps,temp,logs,work,conf,lib}             && 
sudo chmod -R 755 /home/devops/tomcat/bin                                                       

curl -# -L -O https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz &&
tar xf mysql-connector-java-5.1.46.tar.gz                                                        &&
cd "$(find . -type d -name "mysql-connector*")"                                                  &&
sudo mv mysql-connector*.jar /home/devops/tomcat/lib                                             &&

sudo rsync -avz /home/ubuntu/DevOps/tomcat/devops.service      /etc/systemd/system/               &&
sudo rsync -avz /home/ubuntu/DevOps/scripts/devops-service.sh  /home/devops/                      &&
sudo sed -i "s/@@LOCALESUPPORT@@/en_US.utf8/g"                 /home/devops/devops-service.sh     &&
sudo chmod 755 /home/devops/devops-service.sh                                                    &&
sudo systemctl enable devops.service                                                             &&
sudo systemctl daemon-reload                                                                     &&
sudo /home/devops/devops-service.sh start
```

## 1.4.install-MariaDB (yourpassword)

`sudo /home/ubuntu/DevOps/scripts/mariadb.sh`

## 1.5.install-Jenkins: (admin, yourpassword)

```
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -                       &&        
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list' &&
sudo apt-get -qq -y update && sudo apt-get -qq -y install jenkins                                        &&

sudo systemctl start jenkins &&
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
#### sudo nano /etc/default/jenkins >> [default] HTTP_PORT=8081
```

## 2.install-Camunda

`sudo chmod u+x /home/ubuntu/DevOps/scripts/camunda-install.sh`

## 3.install-Alfresco

```
sudo chmod u+x /home/ubuntu/DevOps/scripts/camunda-install.sh                 &&

echo "alfresco  soft  nofile  8192"   | sudo tee -a /etc/security/limits.conf   &&
echo "alfresco  hard  nofile  65536"  | sudo tee -a /etc/security/limits.conf  &&
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session &&
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive
```

## Install Serverless

### Install Python & Pip

> $ `sudo -i`

```
apt-get update &&
apt-get install --yes python &&
apt-get install --yes python-pip   &&
python --version     			  &&
pip --version
```

### //Locale:

> $ `sudo -i`

```
locale-gen && dpkg-reconfigure locales
// `en_US.UTF-8 UTF-8` >> `en_US.utf8` for both prompts
```

### Install MkDocs & MkDocs-Material

> $ `sudo -i`

```
export LC_ALL=C    &&
pip install mkdocs &&
pip install mkdocs-material
```

### Install AWSCLI & Serverless

```
pip install awscli --upgrade --user &&
aws --version
```

## Test

```
lsb_release -a               &&
timedatectl                  &&
free -h                      &&
service nginx status         &&
sudo ufw status numbered     &&
node -v                      &&
npm -v                       &&
pm2 list                     &&
redis-server -v              &&
mongo -version               &&
java -version                &&
mvn -v                       &&
ant -v                       &&
sudo certbot renew --dry-run &&
sudo systemctl status jenkins 
```

## Change ubuntu password
sudo sed -i "s/\(^PasswordAuthentication \).*/\1yes/" /etc/ssh/sshd_config
sudo service sshd restart
sudo usermod --password $(echo PASSWORD | openssl passwd -1 -stdin) $USER
