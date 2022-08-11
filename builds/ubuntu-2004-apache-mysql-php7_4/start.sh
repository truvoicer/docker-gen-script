#!/bin/bash

WEB_ROOT=/var/www/html
SCRIPTS_DIR=/var/scripts
APACHE_VHOSTS_AVAIL_DIR=/etc/apache2/sites-available
APACHE_VHOSTS_ENABLED_DIR=/etc/apache2/sites-enabled
LETSENCRYPT_CERT_DIR=/etc/letsencrypt/live

function FileStringReplace {
  sed -i "s/$1/$2/g" "$3"
}

#REMOVING APACHE DEFAULT HTML
echo REMOVING APACHE DEFAULT HTML
if [ -f "$WEB_ROOT/index.html" ]; then
  rm -r "$WEB_ROOT"/index.html
fi

cd "$WEB_ROOT" || exit

/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
