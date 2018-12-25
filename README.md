# Installing & Configuring DevOps in Ubuntu 16.04 LTS
=======================

## Installation Guideline

| Step | Function Name               | Description                                                                                 |
| :--- |:--------------------------- | :------------------------------------------------------------------------------------------ |
| 01   | S0.os-upgrade.sh         | curl, wget, rsync, zip, unzip, git,  awscli; and SwapFile, en_US.utf8, TimeZone             |
| 02   | 2.install-MEAN.sh           | nginx, nvm, nodejs, pm2, redis, mongo, jenkins, certbot, python, pip, mkdocs, jekyll, gasby |
| 03   | 3.install-JAVA-TOMCAT.sh    | Maven, Ant, Java, Tomcat, Database                                                          |
| 04   | 4.install-alfresco.sh       | Alfresco                                                                                    |
| 05   | 5.install-camunda.sh        | Camunda                                                                                     |
| 06   | 6.install-eforms.sh         | eForm                                                                                       |
| 07   | 7.install-magento2.sh       | Magento2                                                                                    |


## 1. 3rd-Party Software Packagess

| [x] | ## | Software         | Version            | Command                        | PATH                |
| --- | -- | ---------------- | ------------------ | ------------------------------ | ------------------- |
| [x] | 01 | Ubuntu           | Ubuntu 16.04.4 LTS | lsb_release -a                 |                     |
| [x] | 12 | swapfile         |                    | free -h                        |                     |
| [x] | 13 | encoding         |                    |                                |                     |
| [x] | 14 | timezone         |                    | timedatectl                    |                     |
| [x] | 02 | curl             |                    | which curl                     |                     |
| [x] | 03 | wget             |                    | java -version                  | /etc/java-8-oracle/ |
| [-] | 04 | rsync            |                    | mvn -v                         | /usr/share/maven    |
| [x] | 05 | zip              |                    | ant -v                         | /usr/share/ant      |
| [x] | 06 | unzip            |                    | mysql --version                |                     |
| [-] | 07 | git              |                    |                                |                     |
| [x] | 11 | awscli           |                    | libreoffice --version          |                     |
| [x] | 15 | nginx            |                    | sudo service nginx status      |                     |
| [x] | 22 | certbot          |                    | sudo certbot renew --dry-run   |                     |
| [x] | 25 | java             |                    | java -version                  |                     |
| [x] | 21 | jenkins          |                    | sudo service jenkins status    |                     |
| [x] | 08 | python           |                    |                                |                     |
| [x] | 09 | pip              |                    |                                |                     |
| [x] | 10 | mkdocs           |                    |                                |                     |

| [x] | 16 | nvm              |                    | npm -v                         |                     |
| [x] | 17 | nodejs           |                    | node -v                        |                     |
| [x] | 18 | pm2              |                    | pm2 list                       |                     |
| [x] | 19 | redis            |                    | redis-server -v                |                     |
| [x] | 20 | mongodb          |                    | mongo -version                 |                     |


| [x] | 23 | maven            |                    | mvn -v|                        |                     |
| [x] | 24 | ant              |                    | ant -v                         |                     |

| [x] | 26 | tomcat           |                    | telnet localhost 8300          |                     |
| [x] | 27 | PostgreSQL       |                    | telnet localhost [3306 / 5432] |                     |
| [x] | 27 | MariaDB          |                    | telnet localhost [3306 / 5432] |                     |
| [x] | 28 | alfresco         |                    | alfresco.MYCOMPANY.COM         |                     |
| [x] | 29 | camunda          |                    | camunda.MYCOMPANY.COM          |                     |
| [x] | 30 | magento 2        |                    | magento2.MYCOMPANY.COM         |                     |
| [x] | 31 | Wordpress        |                    | magento2.MYCOMPANY.COM         |                     |
| [x] | 32 | Mautic           |                    | magento2.MYCOMPANY.COM         |                     |

> **Checklist**

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
sudo service jenkins status  &&
mvn -v                       &&
ant -v                       &&
sudo certbot renew --dry-run &&
sudo systemctl status jenkins &&
lsof -nP -i4TCP:$PORT | grep LISTEN &&
docker --version             &&
docker-compose --version     &&
git --version
```

### Change Jenkin port

```
sudo sed -i "s/@@PORT@@/8899/g" /etc/nginx/sites-available/jenkins.vboss.tech.conf 
sudo sed -i "s/\(^HTTP_PORT=\).*/\18899/" /etc/default/jenkins
sudo service jenkins restart && sudo service nginx restart
# sudo kill `sudo lsof -t -i:8899`
```
