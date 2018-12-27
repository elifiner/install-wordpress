#!/bin/bash
if [ ! $1 ]; then
    echo "usage $0 <site-name>"
    exit 1
fi

DOMAIN=elifiner.com
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

echo Installing Wordpress...
sudo mkdir -p $SITEDIR
sudo chown -R $USER:www-data $SITEDIR
curl -# https://wordpress.org/latest.tar.gz > $SITEDIR/wordpress.tar.gz
tar xf $SITEDIR/wordpress.tar.gz -C $SITEDIR
mv $SITEDIR/wordpress $SITEDIR/public_html
cp $SITEDIR/public_html/wp-config-sample.php $SITEDIR/public_html/wp-config.php
sed -i \
    -e "s/database_name_here/$DB/" \
    -e "s/username_here/$DB/" \
    -e "s/password_here/$PASSWORD/" \
    -e "s/put your unique phrase here/$PASSWORD/" \
    -e "s/define('WP_DEBUG', false);/define('WP_DEBUG', false);\r\ndefine('FS_METHOD','direct');/" \
    $SITEDIR/public_html/wp-config.php
chmod -R g+w $SITEDIR

echo Configuring Apache2...
cat > /tmp/$SITE.conf <<EOF
<VirtualHost *:80>
    ServerName $SITE.$DOMAIN
    ServerAdmin webmaster@localhost
    DocumentRoot $SITEDIR/public_html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo mv /tmp/$SITE.conf /etc/apache2/sites-available/$SITE.conf
sudo a2ensite $SITE
sudo service apache2 reload

echo "Done."
