#!/bin/bash
if [ ! $1 ]; then
    echo "usage $0 <site-name>"
    exit 1
fi

SITE=$1
DB=wp_$SITE
SITEDIR=/var/www/html/$SITE

read -p "Enter site name again: " SITE_AGAIN

if [ $SITE != $SITE_AGAIN ]; then
    echo "Site names don't match!"
    exit 1
fi

echo Removing database...
sudo mysql <<EOF
    DROP USER $DB@localhost;
    DROP DATABASE IF EXISTS $DB;
EOF

echo Removing Apache2 config...
[ -f /etc/apache2/sites-enabled/$SITE.conf ] && sudo rm /etc/apache2/sites-enabled/$SITE.conf
[ -f /etc/apache2/sites-available/$SITE.conf ] && sudo rm /etc/apache2/sites-available/$SITE.conf

echo Removing Wordpress...
if [ $SITEDIR != "/var/www/html/" ]; then
    sudo rm -rf $SITEDIR
fi
