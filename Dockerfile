FROM ubuntu:16.04

# disable package instalation prompts
ARG DEBIAN_FRONTEND=noninteractive

# update and get required packages for further package install
RUN apt-get update -y; \
    apt-get install --reinstall -y software-properties-common curl git locales-all locales

# add required repositories
RUN add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe'; \
    add-apt-repository ppa:ondrej/apache2; \
    add-apt-repository ppa:ondrej/php; \
    curl -o /tmp/composer-setup.php https://getcomposer.org/installer; \
    curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
    curl -sL https://deb.nodesource.com/setup_8.x | bash -; \
    apt-key update; \
    apt-get update

# install required packahes and clean up the apt cache to reduce image size
RUN apt-get install -y --allow-unauthenticated \
    vim \
    wget \
    lynx \
    psmisc \
    rsync \
    zip \
    gnupg2 \
    bzip2 \
    unzip \
    rsync \
    sudo \
    openssl \
    sshpass \
    mariadb-server \
    apache2 \
    libapache2-mod-fastcgi \
    php7.0-fpm \
    php7.0 \
    php7.0-cli \
    php7.0-common \
    php7.0-json \
    php7.0-simplexml \
    php7.0-curl \
    php7.0-mcrypt \
    php7.0-gd \
    php7.0-intl \
    php7.0-mbstring \
    php7.0-mysql \
    php7.0-xsl \
    php7.0-zip \
    php7.0-opcache \
    php7.0-bcmath \
    php7.0-dom \
    php7.0-soap \
    nodejs; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
    
# install and config composer
RUN php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
    php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer; \
    rm /tmp/composer-setup.php; \
    chmod +x /usr/local/bin/composer

# enable apache required mods and configuration
RUN a2enmod \
    rewrite \
    ssl \
    http2 \
    headers \
    proxy_fcgi \
    env \
    setenvif \
    mpm_event \
    actions \
    fastcgi \
    alias; \
    a2enconf php7.0-fpm; \
    chsh -s /bin/bash www-data

WORKDIR /var/www/html

# remove welcome page set apache permissions and magento user
RUN chgrp www-data /var/www/; \
    chmod g+s /var/www/; \
    adduser magento --gecos "Magento,1,2,3" --disabled-password; \
    usermod -a -G www-data magento; \
    chown magento:www-data /var/www/html
    
# PHP config
COPY .docker/php.ini /usr/local/etc/php
# SSL virtual host conf
COPY .docker/apache.conf /etc/apache2/sites-enabled/000-default.conf
# mysql conf
COPY .docker/mysql.cnf /etc/mysql/mariadb.conf.d/
# database optimiser
COPY .docker/optimiser.sql /optimiser.sql
# run script
COPY .docker/run.sh /run.sh
# magento project files
COPY --chown=magento:www-data . ./
# composer auth keys to download magento
COPY --chown=magento:www-data .docker/auth.json /home/magento/.composer/auth.json

# create handy alias and made for magento bin executable for the user
USER magento

# cd /var/www/html && 
RUN chmod u+x bin/magento; \
    echo "alias magento='php /var/www/html/bin/magento'" >> ~/.bash_aliases; \
    echo "alias gulp='~/.npm-global/lib/node_modules/gulp-cli/bin/gulp.js'" >> ~/.bash_aliases; \
    /bin/bash -c "source ~/.bash_aliases"

# back to root
USER root

# apply recommended magento file permissions
RUN find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +; \
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

# ssl and database ports
EXPOSE 443 3306

# make run script executable
RUN chmod +x /run.sh;

# start running
CMD ["/run.sh"]