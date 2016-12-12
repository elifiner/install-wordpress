#!/bin/bash
set -ex

if [ ! $1 ]; then
    echo "usage $0 <site-name>"
    exit 1
fi

debug=
#debug=echo

SITE=$1
DB=wp_$SITE
SITEDIR=/var/www/html/$SITE
PASSWORD=`python -c 'import os; print os.urandom(16).encode("hex")'`

echo Creating database...
sudo mysql <<EOF
    GRANT USAGE ON *.* TO $DB@localhost;
    DROP USER $DB@localhost;
    DROP DATABASE IF EXISTS $DB;
    CREATE DATABASE $DB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
    GRANT ALL ON $DB.* TO $DB@localhost IDENTIFIED BY '$PASSWORD';
    FLUSH PRIVILEGES;
EOF

echo Configuring Apache2...
cat > /tmp/$SITE.conf <<EOF
<VirtualHost *:80>
    ServerName $SITE.elifiner.com
    ServerAdmin webmaster@localhost
    DocumentRoot $SITEDIR/public_html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
sudo mv /tmp/$SITE.conf /etc/apache2/sites-available/$SITE.conf

echo Installing Wordpress...
sudo mkdir -p $SITEDIR
sudo chown -R $USER:www-data $SITEDIR
curl -# https://wordpress.org/latest.tar.gz > $SITEDIR/wordpress.tar.gz
tar xf $SITEDIR/wordpress.tar.gz
mv wordpress public_html
