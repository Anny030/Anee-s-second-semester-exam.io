#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and upgrade the system
apt update && apt upgrade -y

# Set timezone
timedatectl set-timezone Africa/Lagos

# Install Apache and related packages
apt install -y apache2 apache2-utils elinks

# Install PHP prerequisites
apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 curl wget

# Update Sury source list
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

# Update and upgrade the system again
apt update -y && apt upgrade -y

# Install PHP 8 and modules
apt install -y php8.1 libapache2-mod-php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-xml php8.1-xmlrpc php8.1-curl php8.1-gd php8.1-imagick php8.1-dev php8.1-imap php8.1-mbstring php8.1-opcache php8.1-soap php8.1-zip php8.1-intl php8.1-bcmath

# Add Essentials
apt install -y debconf-utils libaio1

# Disable MySQL setup prompt
debconf-set-selections <<EOF
mysql-apt-config mysql-apt-config/select-server select mysql-8.0
mysql-community-server mysql-community-server/root-pass password root
mysql-community-server mysql-community-server/re-root-pass password root
EOF

# Bypass MySQL setup prompt
wget --user-agent="Mozilla" -O /tmp/mysql-apt-config_0.8.24-1_all.deb https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
sudo DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt-config_0.8.24-1_all.deb < /dev/null > /dev/null

# Update and upgrade the system once more
apt update -y && apt upgrade -y

# Install MySQL
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-server mysql-client --assume-yes --force-yes < /dev/null > /dev/null

# Create MySQL database and user, grant privileges
mysql -e "CREATE DATABASE Anny"
mysql -e "CREATE USER 'Anny'@'localhost' IDENTIFIED BY 'Anny'"
mysql -e "GRANT ALL PRIVILEGES ON Anny.* TO 'Anny'@'localhost'"
mysql -e "FLUSH PRIVILEGES"

# Install Git
apt install -y git

# Install Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

# Setup project
git clone https://github.com/f1amy/laravel-realworld-example-app.git /var/www/annyexam
chown -R www-data:www-data /var/www/annyexam
chmod -R 755 /var/www/annyexam
chgrp -R www-data /var/www/annyexam/storage /var/www/annyexam/bootstrap/cache
chmod -R ug+rwx /var/www/annyexam/storage /var/www/annyexam/bootstrap/cache

# Setup Apache
a2ensite annyexam.conf
a2dissite 000-default.conf
a2enmod rewrite
service apache2 restart

# Configure SSL with Lets Encrypt
apt install snapd -y
snap install core
snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
yes | certbot --apache --agree-tos --redirect -m youremail@email.com -d balogun


