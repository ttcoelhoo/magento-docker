#!/bin/bash

# gracefully stop services when exiting
trap custom_terminate HUP INT QUIT KILL EXIT TERM
function custom_terminate() {
    service apache2 stop
    service php7.0-fpm stop
    /etc/init.d/mysql stop
    exit 0
}

# generate certificates - later you need to make your system trust them
mkdir -p /etc/apache2/ssl
cat <<-EOF > /etc/apache2/ssl/openssl.cnf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = PT
ST = LX
L = Lisbon
O = EAE
OU = Development
CN = $SERVER_NAME
[v3_req]
keyUsage = critical, digitalSignature, keyAgreement
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $SERVER_NAME
EOF

openssl req -x509 -nodes -days 730 -newkey rsa:2048 \
-keyout /etc/apache2/ssl/server.key -out /etc/apache2/ssl/server.crt \
-config /etc/apache2/ssl/openssl.cnf -sha256

# set the server name
echo "ServerName $SERVER_NAME" > /etc/apache2/conf-available/server-name.conf
a2enconf server-name

# start services
rm -f /var/run/apache2/apache2.pid
service apache2 start
service php7.0-fpm start
/etc/init.d/mysql start

# media sync
sshpass -p "$PROVISIONING_SSH_PASS" rsync -rvz -e 'ssh -o StrictHostKeyChecking=no -p 22' \
--progress --ignore-existing --exclude=cache --chown=magento:www-data \
$PROVISIONING_SSH_USER@$PROVISIONING_SSH_HOST:$PROVISIONING_MAGENTO_ROOT/pub/media/ /var/www/html/pub/media/

# create db and user if doesn't exists
if ! [ -d "/var/lib/mysql/$DB_NAME" ] ; then 
printf "\nlocal db doesn't exists "

printf "\ncreate db and user "
mysql -uroot <<-EOF
CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
CREATE DATABASE $DB_NAME;
EOF

if ! [ -z "${PROVISIONING_DB_NAME}" ]; then
    printf "\ndump provisioning db and import..."
    sshpass -p "$PROVISIONING_SSH_PASS" ssh -oStrictHostKeyChecking=no \
    $PROVISIONING_SSH_USER@$PROVISIONING_SSH_HOST "mysqldump $PROVISIONING_DB_NAME | gzip -9" > /docker-entrypoint-initdb.d/provisioning-db.sql.gz
fi
#mysql -uroot $DB_NAME < /optimiser.sql

# search for mysql scripts. provisioning db should be first hence "ls -t"
for f in `ls -t /docker-entrypoint-initdb.d/*`; do
    case "$f" in
        *.sql)    printf "\nrunning $f"; mysql -uroot $DB_NAME < "$f";;
        *.sql.gz) printf "\nrunning $f"; gunzip -c "$f" | mysql -uroot $DB_NAME;;
        *)        printf "\nignoring $f" ;;
    esac
    echo
done

# set magento base_url
mysql -uroot <<-EOF
USE $DB_NAME;
UPDATE core_config_data SET value='https://$SERVER_NAME/' WHERE path IN ('web/unsecure/base_url', 'web/secure/base_url') LIMIT 2;
EOF
fi

# force app/etc/env.php generation and set ownership
php bin/magento setup:install --base-url="https://$SERVER_NAME/" \
--db-name="$DB_NAME" --admin-firstname='admin' --admin-lastname='admin' \
--admin-email='magento@eae.pt' --admin-user='magento-eae' --admin-password='pass123' \
--backend-frontname='admin' --db-host='127.0.0.1' --db-user="$DB_USER" \
--db-password="$DB_PASS" --currency='USD' --timezone='Europe/Lisbon' \
--use-rewrites='1'
chown magento:www-data /var/www/html/app/etc/env.php

# magento deploy
su -c 'bash /var/www/html/.docker/deploy.sh' - magento

# make it run forever
printf "\nit's running...\n"
while true; do sleep 1; done