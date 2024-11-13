#!/bin/bash

#Mostrar los comandos que se van ejecutando 
set -ex

# Importamos las variables de entorno
source .env

#Eliminamos descargas previas del codigo fuente de WordPress
rm -rf /tmp/latest.tar.gz

#Descargamos el codigo fuente de WordPress
wget http://wordpress.org/latest.tar.gz -P /tmp

#Descomprimimos el codifo fuente de WordPress
tar -xzvf /tmp/latest.tar.gz -C /tmp

#Borramos instalaciones precias que haya en /var/www/html de WordPress
rm -rf /var/www/html/*

#Creamos el directorio para la instalacion de WordPress
mkdir -p /var/www/html/$WORDPRESS_DIRECTORY

#Movemos el codigo fuente de WordPress a /var/www/html
mv -f /tmp/wordpress/* /var/www/html/$WORDPRESS_DIRECTORY

#Creamos la base de datos y el usuario para WordPress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

#Creamos el archivo de configuracoin de WordPress
cp /var/www/html/$WORDPRESS_DIRECTORY/wp-config-sample.php /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php

#Configuramos el archivo de configuracion de WordPress
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
 
sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$LE_DOMAIN/$WORDPRESS_DIRECTORY');" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$LE_DOMAIN');" /var/www/html/$WORDPRESS_DIRECTORY/wp-config.php

#COpiamos el archivo index.php
cp /var/www/html/$WORDPRESS_DIRECTORY/index.php /var/www/html

#Configuramos el archivo index.php
sed -i "s#wp-blog-header.php#$WORDPRESS_DIRECTORY/wp-blog-header.php#" /var/www/html/index.php 

#Modificamos los propietarios y el grupo del directorio /var/www/html
chown -R www-data:www-data /var/www/html/

# Eliminamos los valores por defecto de las security keys que aparecen en el archivo de configuración.
sed -i "/AUTH_KEY/d" /var/www/html/miwordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/miwordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/miwordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/miwordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/miwordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/miwordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/miwordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/miwordpress/wp-config.php

#Hacemos una llamada a la API de wordpress para obtener las security keys y almacenamos el resultado en una variable de entorno.
SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)

# Para evitar posibles problemas con el carácter / vamos a reemplazarlo por el carácter _.
SECURITY_KEYS=$(echo $SECURITY_KEYS | tr / _)

#Añadimos las security keys al archivo de configuración.
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/miwordpress/wp-config.php

#Cambiamos el propietario y el grupo al directorio /var/www/html.
chown -R www-data:www-data /var/www/html/