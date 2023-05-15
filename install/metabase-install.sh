#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P  )
cd $SCRIPT_PATH

source ./metabase.properties

sudo apt install $MB_JAVA_VERSION -y
sudo apt install postgresql postgresql-contrib -y
sudo apt install apache2 -y

# remove the apache default site
sudo unlink /etc/apache2/sites-enabled/000-default.conf

# install apache modules
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_ajp
sudo a2enmod rewrite
sudo a2enmod deflate
sudo a2enmod headers
sudo a2enmod proxy_balancer
sudo a2enmod proxy_connect
sudo a2enmod proxy_html
sudo a2enmod dbd
sudo a2enmod authn_dbd
sudo a2enmod ssl
sudo service apache2 restart

# get current user/group
# assumes sudo privilege
CUR_OSUSER=$(id -u -n)
echo CUR_OSUSER=$CUR_OSUSER
CUR_OSUSER_GROUP=$(id -g -n)
echo CUR_OSUSER_GROUP=$CUR_OSUSER_GROUP

# create unprivileged user
sudo adduser $MB_OS_USER --disabled-password --gecos "$MB_OS_USER,none,none,none"

# copy metabase apache config
sudo cp ../web/000-metabase.conf /etc/apache2/sites-enabled/.
sudo service apache2 restart

# moved to proper directory
sudo mkdir -p /opt/$MB_OS_USER/plugins
sudo chown -R $CUR_OSUSER:$CUR_OSUSER_GROUP /opt/$MB_OS_USER/
cp * /opt/$MB_OS_USER/.
cd /opt/$MB_OS_USER/
rm metabase-install.sh
rm metabase-remove.sh

# install metabase and configure database
wget $MB_JAR
sudo -u postgres createuser $MB_DB_USER
sudo -u postgres createdb $MB_DB_DBNAME
sudo -u postgres psql -c "alter user $MB_DB_USER with encrypted password '$MB_DB_PASS'"
sudo -u postgres psql -c "grant all privileges on database $MB_DB_DBNAME to $MB_DB_USER"

# start metabase
echo starting metabase ....
echo check /opt/$MB_OS_USER/metabase.log for details if needed...
echo
./metabase-start.sh

echo "You need an https cert"
echo "You can either sign your own or use certbot"
echo "Here is a script to sign your own: https://github.com/chuboe/idempiere-installation-script/blob/master/utils/chuboe_selfsign_cert.sh"
