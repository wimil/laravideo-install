#!/bin/bash

source ./helpers/init.sh

#Descargamos el script
if [[ $install_type == "encoder" ]]; then
    git clone https://github.com/wimil/laravideo-encoder.git
else
    git clone https://github.com/wimil/laravideo-storage.git
fi

# Instalamos utilitarios
yum install epel-release nano wget unzip -y

#Instalamos nginx, lo habilitamos e iniciamos
yum install nginx -y
systemctl enable nginx
systemctl start nginx

message "success" "Nginx Instalado y configurado"

# Instalamos php 7.4
yum install yum-utils -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum --disablerepo="*" --enablerepo="remi-safe" list php[7-9][0-9].x86_64
yum-config-manager --enable remi-php74
yum install php php-fpm php-common php-bcmath php-xml php-mbstring php-json php-zip php-mysqlnd php-pear php-devel -y
systemctl enable php-fpm

# Configuramos php-fpm
cat utils/www.conf >/etc/php-fpm.d/www.conf
systemctl start php-fpm

message "success" "PHP 7.4 Instalado y configurado"

# Creamos el folder para el server block
mkdir -p $server_root/public
#touch $server_root/public/info.php
#echo '<?php phpinfo() ?>' >>$server_root/public/info.php

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

message "success" "Certbot Instalado y configurado"

# Instalar Pure-Ftp
yum install pure-ftpd -y
cat utils/pure-ftpd.conf >/etc/pure-ftpd/pure-ftpd.conf
mkdir -p /etc/ssl/private/
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -subj "/C=US/ST=Denial/L=Springfield/O=Rldev/OU=IT Department/CN=$server_name"
chmod 600 /etc/ssl/private/pure-ftpd.pem
systemctl enable pure-ftpd
systemctl start pure-ftpd
(
    echo $ftp_password
    echo $ftp_password
) | pure-pw useradd $ftp_user -u nginx -g nginx -d $server_root
chown -R nginx:nginx $server_root
pure-pw mkdb
systemctl restart pure-ftpd

echo "User: $ftp_user - Password: $ftp_password" >~/ftp_data.txt

message "success" "PureFtp Instalado y configurado"

#Instalamos supervisor
yum -y install supervisor
systemctl start supervisord
systemctl enable supervisord

message "success" "Supervisor Instalado"

#instalamos composer
source ./scripts/install_composer.sh

message "success" "Composer Instalado y configurado"

# Instalar firewall
yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --zone=public --add-service=http --add-service=https --add-service=ftp

message "success" "Firewalld instalado y configurado"

#Copiamos el script al server block y configuramos
rm -rf $server_root
mkdir -p $server_root
shopt -s dotglob
mv laravideo-encoder/* $server_root/
cd $server_root
mv .env.example .env
composer install

cd ~/laravideo-install

chown -R nginx:nginx $server_root
chcon -Rt httpd_sys_content_t $server_root
semanage fcontext -a -t httpd_sys_rw_content_t "$server_root/storage(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$server_root/bootstrap/cache(/.*)?"
restorecon -Rv /var/www/$server_root
setsebool -P httpd_can_network_connect_db 1

message "success" "Server block configurado!"

if [[ $install_type == 'encoder' ]]; then

    # Upload File Size
    sed '/http {/a \    client_max_body_size 3500M;' -i /etc/nginx/nginx.conf
    sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 3000M,' /etc/php.ini
    sed -i 's,^post_max_size =.*$,post_max_size = 3500M,' /etc/php.ini
    systemctl restart php-fpm
    systemctl restart nginx

    # Movemos los binarios ffmpeg
    mv $server_root/ffmpeg/ffmpeg /usr/bin/ffmpeg
    mv $server_root/ffmpeg/ffprobe /usr/bin/ffprobe
    chmod +x /usr/bin/ffmpeg
    chmod +x /usr/bin/ffprobe
    chcon -t execmem_exec_t '/usr/bin/ffmpeg'
    chcon -t execmem_exec_t '/usr/bin/ffprobe'

    # Configurando el supervisor
    touch /etc/supervisord.d/encoder.ini
    cat utils/supervisor/encoder.ini >/etc/supervisord.d/encoder.ini
    sed -i "s/{server_name}/$server_name/g" /etc/supervisord.d/encoder.ini

    touch /etc/supervisord.d/storing.ini
    cat utils/supervisor/storing.ini >/etc/supervisord.d/storing.ini
    sed -i "s/{server_name}/$server_name/g" /etc/supervisord.d/storing.ini

    message "success" "Tipo encoder Configurado!!"

else
    touch /etc/supervisord.d/ipfs.ini
    cat utils/supervisor/ipfs.ini >/etc/supervisord.d/ipfs.ini
    sed -i "s/{server_name}/$server_root/g" /etc/supervisord.d/ipfs.ini

    message "success" "Tipo storage Configurado!!"
fi

supervisorctl reload
message "success" "Supervisor configurado"

reboot
