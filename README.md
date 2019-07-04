# Magento Docker Image

This is for Magento development purposes. Optimised for 2.2.x using snowdog frontools and php7.0 fpm  

The base url of your development site depends the server name you choose. Eg. if the server name is www.magento.docker then the base url will be https://www.magento.docker/

Depending on that you need to change your hosts file pointing the base url to localhost.

Put your Magento project files directly on the root.

## Environment Variables

You need to set these vars:

##### SERVER_NAME
The apache server name that will also be used for the base url eg www.magento.docker 

##### DB_NAME
Database name

##### DB_USER=magento2 
Database user

##### DB_PASS=magento2 
Database password

##### PROVISIONING_SSH_HOST
Provisioning host

##### PROVISIONING_SSH_USER
Provisioning SSH user

##### PROVISIONING_SSH_PASS
Provisioning SSH pass

##### PROVISIONING_DB_NAME
Provisioning DB name

##### PROVISIONING_MAGENTO_ROOT
Provisioning DB name Magento file root eg. /var/www/html

## Docker Run example
``` 
docker run -t -i \
    -v '/LOCAL_MAGENTO_DIR/app:/var/www/html/app' \
    -v '/LOCAL_MAGENTO_DIR/pub/media:/var/www/html/pub/media' \
    -p 3306:3306 -p 443:443 \
    -e SERVER_NAME=www.magento2.docker \
    -e DB_NAME=magento2 \
    -e DB_USER=magento2 \
    -e DB_PASS=magento2 \
    -e CLONE_SSH_HOST=staging.magento2.net \
    -e CLONE_SSH_USER=user \
    -e CLONE_SSH_PASS=pass123 \
    -e CLONE_DB_NAME=staging \
    -e CLONE_MAGENTO_ROOT=/var/www/html \
    magento-docker:2.2-php7.0
```


## HTTPS

It uses https only so port 80 is not exposed. This is because doesn't make sense developing non https for e-commerce stores. Also some magento module integrations require https. When running the docker image SSL keys are generated accordingly to the server name you choose. Then when accessing the via browser you need to download the self signed generated certificate and make you system trust it. Avoid using a server name with *.dev super domain.

[https://www.accuweaver.com/2014/09/19/make-chrome-accept-a-self-signed-certificate-on-osx/](https://www.accuweaver.com/2014/09/19/make-chrome-accept-a-self-signed-certificate-on-osx/)

## Provisioning environment

It demands having a provisioning environment from where you can clone database and media files via SSH, for instance can be the staging environment of your project. It's prepared for ssh through password, not keys unfortunately.
