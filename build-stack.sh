#!/usr/bin/env bash
# created by Dave Hilditch @ www.wpintense.com

DBPASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c32)"
WPADMINPASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)"

echo "Adresse mail à utiliser ? (utilisée pour le certificat SSL wp-admin)"
read ADMINEMAIL

echo "quelle sera l\'URL du site? "
read SITEURL

echo "definir un nom d\'utilisateur pour la base de donnée :"
read DBUSER

echo "$DBPASSWORD" > dbpassword.txt
echo "$WPADMINPASSWORD" > wpadminpassword.txt


#nginx config
#git clone https://github.com/dhilditch/wpintense-rocket-stack-ubuntu18-wordpress /root/rsconfig
#cp /root/rsconfig/nginx/* /etc/nginx/ -R

cp /etc/nginx/sites-available/rocketstack.conf /etc/nginx/sites-available/$SITEURL.conf
ln -s /etc/nginx/sites-available/$SITEURL.conf /etc/nginx/sites-enabled/
mkdir /var/www/$SITEURL/cache
chown www-data:www-data /var/www/$SITEURL/cache/
#change server_name variable to domain name of website inc www
sed -i "s/server_name _;/server_name $SITEURL;/gi" /etc/nginx/sites-available/$SITEURL.conf

service nginx restart

#mysql config
mysql -e "CREATE DATABASE $DBUSER;"
mysql -e "CREATE USER '$DBUSER'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DBPASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON $DBUSER.* TO '$DBUSER'@'localhost';"



certbot --nginx --non-interactive --agree-tos --email $ADMINEMAIL --domains $SITEURL
service nginx restart

#wordpress installation

mkdir /var/www/rocketstack
chown www-data:www-data /var/www/rocketstack
cd /var/www/rocketstack
wp core download --allow-root
chown www-data:www-data * -R
wp core config --dbhost=localhost --dbname=rocketstack --dbuser=rs --dbpass=$DBPASSWORD --allow-root
chmod 644 wp-config.php
wp core install --url="https://${SITEURL}" --title="Rocket Stack Installation by www.wpintense.com" --admin_name=rsadmin --admin_password=$WPADMINPASSWORD --admin_email=$ADMINEMAIL  --allow-root
chown www-data:www-data /var/www/rocketstack -R

#wget https://wordpress.org/latest.zip -P /var/www/
#unzip /var/www/latest.zip -d /var/www/
#mv /var/www/wordpress /var/www/rocketstack
#chown www-data:www-data /var/www/rocketstack -R
#rm /var/www/latest.zip

#mysql_secure_installation # choose y for everything and enter a secure root password
echo "You can now log in through https://${SITEURL}/wp-login.php"
echo "Username: rsadmin";
echo "Password: $WPADMINPASSWORD";


