#!/bin/bash

#Mostrar los comandos que se van ejecutando 
set -ex

# Importamos las variables de entorno
source .env

#Eliminamos descargas prevas de WP-CLI
rm -rf /tmp/wp-cli.phar

#Descargamos WP-CLI
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

#Le damos permisos de ejecucion 
chmod +x /tmp/wp-cli.phar

#Movemos el script WP-CLI al  directorio /usr/local/bin
mv /tmp/wp-cli.phar /usr/local/bin/wp

#ELiminamos instalaciones previas en /var/www/html
rm -rf ${WORDPRESS_DIRECTORY}/*

#Descargamos el codigo fuente de WordPress
wp core download --locale=es_ES --path=/var/www/html --allow-root

#Creamos la base de datos y el usuario para WordPress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

#Creamos el archivo de configuracion
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --dbhost=$WORDPRESS_DB_HOST \
  --path=$WORDPRESS_DIRECTORY \
  --allow-root


wp core install \
  --url=$LE_DOMAIN \
  --title=$WORDPRESS_TITLE \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASS \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=$WORDPRESS_DIRECTORY \
  --allow-root 

# Instalamos y activamos el theme mindscape
wp theme install mindscape --activate --path=$WORDPRESS_DIRECTORY --allow-root

# Instalamos un plugin
wp plugin install wps-hide-login --activate --path=$WORDPRESS_DIRECTORY --allow-root

# Configuramos el plugin de url
wp option update whl-page "$WORDPRESS_HIDE_LOGIN_URL" --path=$WORDPRESS_DIRECTORY --allow-root

# Configuramos los enlaces permanentes
wp rewrite structure '/%postname%/' --path=$WORDPRESS_DIRECTORY --allow-root

#Copiamos el archivo .htaccess
cp ../htaccess/.htaccess $WORDPRESS_DIRECTORY

# Modificamos el propietario y el grupo del directorio /var/www/html
chown -R www-data:www-data $WORDPRESS_DIRECTORY
