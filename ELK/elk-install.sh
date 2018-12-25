sudo hostnamectl set-hostname "elk.vboss.tech"
echo "13.237.215.18  elk.vboss.tech elk" | sudo tee --append /etc/hosts


cd ~/download


###########################
# 1. RedHat Upgrade 
###########################
sudo yum update

##LOCALE##
if [ -f "/etc/profile.d/lang.sh" ]; then
	source /etc/profile.d/lang.sh
fi
cat /dev/null                      | sudo tee --append /etc/locale.conf
echo "export LANG=en_US.UTF-8"     | sudo tee --append	~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" | sudo tee --append	~/.bashrc
echo "export LC_COLLATE=C"         | sudo tee --append	~/.bashrc
echo "export LC_CTYPE=en_US.UTF-8" | sudo tee --append	~/.bashrc
source ~/.bashrc

sudo timedatectl set-timezone Asia/Ho_Chi_Minh 
sudo timedatectl set-ntp yes                    
sudo dd if=/dev/zero of=/swapfile bs=1024 count=16384                  
sudo mkswap /swapfile                                             
sudo chmod 0600 /swapfile                                         
sudo cp /etc/fstab /etc/fstab.bak                                 
echo "/swapfile swap swap defaults 0 0" | sudo tee --append /etc/fstab   
sudo systemctl daemon-reload                                      
sudo swapon /swapfile
echo "search vboss.tech"                | sudo tee --append /etc/resolv.conf  


###########################
# 2. Install Oracle JDK 
###########################

if [ "`which java`" = "" ]; then
  echoblue "Installing Oracle Java 8. Fetching packages..."
  wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.tar.gz" -P ~/download/

  sudo mkdir /usr/java
  sudo tar xvzf ~/download/jdk-8u181-linux-x64.tar.gz -C /usr/java
  
  #export JAVA_DEST=jdk1.8.0_181
  JAVA_DEST=jdk1.8.0_181
  export JAVA_HOME=/usr/java/$JAVA_DEST/
  sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 1
  sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 1

  echo
  echogreen "Finished installing Oracle Java 8"
  echo
fi


###########################
# 3. Install Firewalld
###########################

sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9200/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5601/tcp --permanent
sudo firewall-cmd --reload
## sudo firewall-cmd --list-all


###########################
# 4. Install Docker
###########################

## RHEL6  insert this --insecure-registry 172.30.1.1:5000 into /etc/sysconfig/docker
cat /dev/null | sudo tee /etc/docker/daemon.json
echo "{\"insecure-registries\": [\"$DOCKER_INSECURE_IP_RANGE\"]}" | sudo tee --append /etc/docker/daemon.json
# Add ec2-user to docker
# sudo usermod -aG docker ec2-user
sudo systemctl restart docker.service


###########################
# 5. Install ElasticSearch 6.x: `/etc/elasticsearch/elasticsearch.yml`
###########################

sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

echo "[elasticsearch-6.x]"                                       | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "name=Elasticsearch repository for 6.x packages"            | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "baseurl=https://artifacts.elastic.co/packages/6.x/yum"     | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "gpgcheck=1"                                                | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "enabled=1"                                                 | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "autorefresh=1"                                             | sudo tee --append /etc/yum.repos.d/elasticsearch.repo
echo "type=rpm-md"                                               | sudo tee --append /etc/yum.repos.d/elasticsearch.repo

sudo yum -y install elasticsearch

## Configuring ElasticSearch
sudo firewall-cmd --zone=public --add-port=9200/tcp --permanent
sudo firewall-cmd --reload
## ifconfig localhost 172.31.1.143
## echo "http.port: 9200" | sudo tee --append /etc/elasticsearch/elasticsearch.yml
echo "network.host: 172.31.1.143" | sudo tee --append /etc/elasticsearch/elasticsearch.yml
# echo "thread_pool.search.min_queue_size: 2000" | sudo tee --append /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.enabled: false" | sudo tee --append /etc/elasticsearch/elasticsearch.yml

## To configure Elasticsearch to start automatically when the system boots up
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

sudo -i service elasticsearch start
## sudo -i service elasticsearch stop


###########################
# 6. Install Logstash
###########################

echo "[logstash-6.x]"                                            | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "name=Elastic repository for 6.x packages"                  | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "baseurl=https://artifacts.elastic.co/packages/6.x/yum"     | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "gpgcheck=1"                                                | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "enabled=1"                                                 | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "autorefresh=1"                                             | sudo tee --append /etc/yum.repos.d/logstash.repo
echo "type=rpm-md"                                               | sudo tee --append /etc/yum.repos.d/logstash.repo

sudo yum -y install logstash

## To configure Logstash to start automatically when the system boots up
## "172.31.1.143:5044"
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable logstash.service

sudo -i service logstash start
## sudo -i service logstash stop

###########################
# 7. Install Kibana: `/etc/kibana/kibana.yml`
###########################

echo "[kibana-6.x]"                                              | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "name=Kibana repository for 6.x packages"                   | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "baseurl=https://artifacts.elastic.co/packages/6.x/yum"     | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "gpgcheck=1"                                                | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "enabled=1"                                                 | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "autorefresh=1"                                             | sudo tee --append /etc/yum.repos.d/kibana.repo
echo "type=rpm-md"                                               | sudo tee --append /etc/yum.repos.d/kibana.repo

sudo yum -y install kibana

## Configuring Kibana
sudo firewall-cmd --zone=public --add-port=5601/tcp --permanent
sudo firewall-cmd --reload

echo "xpack.security.enabled: false" | sudo tee --append /etc/kibana/kibana.yml

```
server.port: 5601
server.host: "172.31.1.143"
elasticsearch.url: "http://172.31.1.143:9200"
```

## Kibana will start automatically when the system boots up
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service

sudo systemctl start kibana.service
## sudo -i service kibana stop
## journalctl -u kibana.service

## Install Metricbeat
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-6.3.2-x86_64.rpm
sudo rpm -vi metricbeat-6.3.2-x86_64.rpm
sudo metricbeat modules enable system
## --> sudo nano /etc/metricbeat/modules.d/system.yml
sudo metricbeat setup -e
# sudo metricbeat setup
# sudo metricbeat setup --dashboards
sudo service metricbeat start

###
# sudo nano /etc/metricbeat/metricbeat.yml
# 
# output.elasticsearch:
#   hosts: ["172.31.1.143:9200"]
# setup.kibana:
#   host: "172.31.1.143:5601"
###

###########################
# 8. Install Jenkins: `/etc/yum.repos.d/jenkins.repo`
###########################
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
sudo yum -y install jenkins

## sudo service jenkins start/stop/restart
## `systemctl enable jenkins` --> `sudo /sbin/chkconfig jenkins on`
sudo service jenkins start
sudo /bin/systemctl enable jenkins

## Configuring Jenkins
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload

## Jenkins user
sudo cp -rf ~/.aws /var/lib/jenkins/
sudo -i
chown jenkins:jenkins -R /var/lib/jenkins/.aws
su - jenkins
aws --version






