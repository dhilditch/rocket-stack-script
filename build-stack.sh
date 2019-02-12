#!/usr/bin/env bash
# created by Dave Hilditch @ www.wpintense.com

DBPASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c32)"
WPADMINPASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)"
echo "Which URL should I configure this build for? (e.g. www.wpintense.com)"
read SITEURL

echo "$DBPASSWORD" > dbpassword.txt
echo "$WPADMINPASSWORD" > wpadminpassword.txt

export DEBIAN_FRONTEND=noninteractive
wget -c https://dev.mysql.com/get/mysql-apt-config_0.8.10-1_all.deb
dpkg -i mysql-apt-config_0.8.10-1_all.deb
apt-get update -y
apt-get upgrade -y
apt-get install debconf-utils -y
echo "mysql-community-server  mysql-server/default-auth-override      select  Use Strong Password Encryption (RECOMMENDED)" | debconf-set-selections
apt-get install mysql-server -y # accept all defaults
apt-get install php7.2 -y
apt-get purge apache2 -y
apt-get install nginx -y
apt-get install -y tmux curl wget php7.2-fpm php7.2-cli php7.2-curl php7.2-gd php7.2-intl 
apt-get install -y php7.2-mysql php7.2-mbstring php7.2-zip php7.2-xml unzip
apt-get install -y redis
apt-get install -y fail2ban

#redis config
echo "maxmemory 300mb" > /etc/redis/redis.conf
echo "maxmemory-policy allkeys-lru" > /etc/redis/redis.conf

sed -i 's/^save /#save /gi' /etc/redis/redis.conf

#nginx config
git clone https://github.com/dhilditch/wpintense-rocket-stack-ubuntu18-wordpress /root/rsconfig
cp /root/rsconfig/nginx/* /etc/nginx/ -R
ln -s /etc/nginx/sites-available/rocketstack.conf /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
mkdir /var/www/cache
chown www-data:www-data /var/www/cache/
#TODO: change server_name variable to domain name of website inc www
sed -i "s/server_name _;/server_name $SITEURL;/gi" /etc/nginx/sites-available/rocketstack.conf

service nginx restart

#mysql config
mysql -e "CREATE DATABASE rocketstack;"
#mysql -e "CREATE USER 'rs'@'localhost' IDENTIFIED WITH mysql_native_password BY 'MIRRR7Zl6gMFntIruhBsHMhgAXfD7BZL';"
mysql -e "CREATE USER 'rs'@'localhost' IDENTIFIED BY '${DBPASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON rocketstack.* TO 'rs'@'localhost';"

#mysql innodb config
echo "innodb_buffer_pool_size = 200M" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "innodb_buffer_pool_instances = 8" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "innodb_io_capacity = 5000" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "max_binlog_size = 100M" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "expire_logs_days = 3" >> /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart

#config php.ini
sed -i 's/^max_execution_time = 30/max_execution_time = 600/gi' /etc/php/7.2/fpm/php.ini
sed -i 's/^memory_limit = 128M/memory_limit = 512M/gi' /etc/php/7.2/fpm/php.ini
sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 20M/gi' /etc/php/7.2/fpm/php.ini

#config www.conf
sed -i 's/^pm = dynamic/pm = static/gi' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/^pm.max_children = 5/pm.max_children = 25/gi' /etc/php/7.2/fpm/pool.d/www.conf

service php7.2-fpm restart

apt-get install software-properties-common -y
add-apt-repository universe -y
add-apt-repository ppa:certbot/certbot -y
apt-get update -y
apt-get install python-certbot-nginx -y
certbot --nginx --non-interactive --agree-tos 
service nginx restart

#wordpress installation
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
mkdir /var/www/rocketstack
chown www-data:www-data /var/www/rocketstack
cd /var/www/rocketstack
wp core download --allow-root
chown www-data:www-data * -R
wp core config --dbhost=localhost --dbname=rocketstack --dbuser=rs --dbpass=$DBPASSWORD --allow-root
chmod 644 wp-config.php
wp core install --url="https://${SITEURL}" --title="Rocket Stack Installation by www.wpintense.com" --admin_name=rsadmin --admin_password=$WPADMINPASSWORD --admin_email=you@example.com  --allow-root

#wget https://wordpress.org/latest.zip -P /var/www/
#unzip /var/www/latest.zip -d /var/www/
#mv /var/www/wordpress /var/www/rocketstack
#chown www-data:www-data /var/www/rocketstack -R
#rm /var/www/latest.zip

#mysql_secure_installation # choose y for everything and enter a secure root password
echo "You can now log in through https://${SITEURL}/wp-login.php"
echo "Username: rsadmin";
echo "Password: $WPADMINPASSWORD";


