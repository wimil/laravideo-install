#!/bin/bash

source ./helpers/init.sh

# Instalamos utilitarios
yum install epel-release nano wget unzip -y

#Instalamos nginx, lo habilitamos e iniciamos
yum install nginx -y
systemctl enable nginx
systemctl start nginx

# Instalamos php 7.4
yum install yum-utils -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum --disablerepo="*" --enablerepo="remi-safe" list php[7-9][0-9].x86_64
yum-config-manager --enable remi-php74
yum install php php-fpm php-common php-xml php-mbstring php-json php-zip php-mysqlnd php-pear php-devel -y
systemctl enable php-fpm

# Configuramos php-fpm
cat utils/www.conf >/etc/php-fpm.d/www.conf
systemctl start php-fpm

# Creamos el folder para el server block
mkdir -p $server_root/public
touch $server_root/public/info.php
echo '<?php phpinfo() ?>' >>$server_root/public/info.php

# Instalar certbot
yum install certbot python2-certbot-nginx -y
certbot certonly --webroot --non-interactive --agree-tos --register-unsafely-without-email -w /usr/share/nginx/html -d $server_name

# Configuramos nginx el server block
touch /etc/nginx/conf.d/$server_name.conf
cat utils/server_block.conf >/etc/nginx/conf.d/$server_name.conf
sed -i "s/{server_name}/$server_name/g" /etc/nginx/conf.d/$server_name.conf
systemctl restart nginx

# Creamos un cron para renovar el ceritficado
mv utils/letsencrypt-renew /etc/cron.daily/letsencrypt-renew
chmod +x /etc/cron.daily/letsencrypt-renew
crontab -l | {
    cat
    echo "01 02,14 * * * /etc/cron.daily/letsencrypt-renew"
} | crontab -

# Instalar Pure-Ftp
yum install pure-ftpd -y
cat utils/pure-ftpd.conf >/etc/pure-ftpd/pure-ftpd.conf
mkdir -p /etc/ssl/private/
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -subj "/C=US/ST=Denial/L=Springfield/O=Rldev/OU=IT Department/CN=$server_name"
chmod 600 /etc/ssl/private/pure-ftpd.pem
systemctl enable pure-ftpd
systemctl start pure-ftpd
(echo $ftp_password; echo $ftp_password) | pure-pw useradd $ftp_user -u nginx -g nginx -d $server_root
chown -R nginx:nginx $server_root
pure-pw mkdb
systemctl restart pure-ftpd

# Instalmos ssh2 para interactuar con los archivos
#yum install libssh2-devel -y
#wget https://pecl.php.net/get/ssh2-1.2.tgz
#printf "\n" | pecl install ssh2-1.2.tgz
#echo "extension=ssh2.so" >>/etc/php.ini
#systemctl restart php-fpm

#instalamos composer
source ./scripts/install_composer.sh

# Instalar firewall
yum install firewalld -y
sudo systemctl start firewalld
sudo systemctl enable firewalld
firewall-cmd --permanent --zone=public --add-service=http --add-service=https --add-service=ftp
reboot