#!/usr/bin/env bash
wget -c https://dev.mysql.com/get/mysql-apt-config_0.8.10-1_all.deb
dpkg -i mysql-apt-config_0.8.10-1_all.deb
apt-get update
apt-get upgrade
apt-get install mysql-server -y # accept all defaults
apt-get -y install php7.2
apt-get purge apache2
apt-get install nginx
apt-get install -y tmux curl wget php7.2-fpm php7.2-cli php7.2-curl php7.2-gd php7.2-intl 
apt-get install -y php7.2-mysql php7.2-mbstring php7.2-zip php7.2-xml unzip
apt-get install -y redis
apt-get install -y fail2ban

mysql_secure_installation # choose y for everything and enter a secure root password
