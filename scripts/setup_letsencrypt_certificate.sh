#!/bin/bash

#Mostrar los comandos que se van ejecutando 
set -ex

# Importamos las variables de entorno
source .env

#Instalamos y actualizamos snap core
snap install core
snap refresh core

#Eliminamos si existiese alguna instalación previa de certbot con apt.
apt remove certbot -y

#Instalamos el cliente de Certbot con snapd.
snap install --classic certbot

# Creamos una alias para el comando certbot.
ln -fs /snap/bin/certbot /usr/bin/certbot

#Solicitamos un certificado a Let's Encrypt
certbot --apache -m $LE_EMAIL --agree-tos --no-eff-email -d $LE_DOMAIN --non-interactive