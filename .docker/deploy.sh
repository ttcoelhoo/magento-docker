#!/bin/bash

# create handy alias and made for magento bin executable for the user
chmod u+x /var/www/html/bin/magento; \
echo "alias magento='php /var/www/html/bin/magento'" >> ~/.bash_aliases; \
echo "alias gulp='~/.npm-global/lib/node_modules/gulp-cli/bin/gulp.js'" >> ~/.bash_aliases; \
/bin/bash -c "source ~/.bash_aliases"

# create user composer dir and install
mkdir -p ~/.composer
cd /var/www/html && composer install; \

# same for npm
mkdir ~/.npm-global; \
npm config set prefix '~/.npm-global'; \
export PATH=~/.npm-global/bin:$PATH; \
/bin/bash -c "source ~/.profile"; \
npm install; \

# setup gulp part of snowdog frontools package and add our themes configuration, additional tasks
cd /var/www/html/vendor/snowdog/frontools
npm install
npm install gulp-cli -g

# because the package.json would be overrided by the install, specific packages are installed after
npm install gulp node-sass@4.7.2 gulp-htmlmin;
rsync -a /var/www/html/dev/tools/frontools/additional-tasks/ /var/www/html/vendor/snowdog/frontools/task/
rsync -a /var/www/html/dev/tools/frontools/config/ /var/www/html/vendor/snowdog/frontools/config/

# set magento mode, upgrade, compile, deploy static files and compile it
php /var/www/html/bin/magento deploy:mode:set developer
php /var/www/html/bin/magento maintenance:enable
php /var/www/html/bin/magento setup:upgrade
php /var/www/html/bin/magento setup:di:compile
php /var/www/html/bin/magento setup:static-content:deploy en_US en_GB -f
cd /var/www/html/vendor/snowdog/frontools
/home/magento/.npm-global/lib/node_modules/gulp-cli/bin/gulp.js setup
/home/magento/.npm-global/lib/node_modules/gulp-cli/bin/gulp.js styles
/home/magento/.npm-global/lib/node_modules/gulp-cli/bin/gulp.js babel
php /var/www/html/bin/magento maintenance:disable