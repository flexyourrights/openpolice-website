#!/bin/bash
set +x
echo '======================================'
echo 'Local OpenPoliceExtension Installation'
echo '--------------------------------------'
echo 'To be run in code folder of Homestead'
echo '======================================'
echo ''
read -p $'What is the directory for this local OpenPoliceExtension installation (relative to current folder)?\nIf it exists, it will be deleted for a fresh install.\n(e.g. myopenpolice)\n' dir
echo ''
read -p $'What is the database name for this installation, already created in Homestead?\n(e.g. myopenpolice)\n' dbname
echo ''
read -p $'Would you like to import United States police departments?\n("y" or "n")\n' uploaddepts
echo ''
read -p $'Would you like to import United States zip codes?\n("y" or "n")\n' uploadzips
echo ''

if [ $# -eq 1 ]; then
    set -x
fi

if [ ! -f scripts-openpolice-extension/mac/helpers-installed.txt ]; then
    echo '------------------------'
    echo 'Install Homebrew Helpers'
    echo '========================'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    xcode-select --install
    brew update
    brew install perl
    brew install php@7.4
    brew services start php@7.4
    brew link php@7.4 --force
    brew link --force --overwrite php@7.4
    echo 'Helpers installed.' >> scripts-openpolice-extension/mac/helpers-installed.txt
fi

echo ''
echo '--'
echo '----'
echo '--------'
echo 'Install Laravel Framework'
echo '========================='
if [ -d "$dir" ]; then
    rm -R ./$dir
fi
composer create-project laravel/laravel $dir "8.5.*"
cd $dir
mv ./.env ./orig.env
cp ../scripts-openpolice-extension/mac/op.env ./.env
perl -pi -w -e "s/DB_DATABASE=myopenpolice/DB_DATABASE=$dbname/g" ./.env
perl -pi -w -e "s/myopenpolice.local/$dir.local/g" ./.env
php artisan key:generate
php artisan config:clear
php artisan route:clear
php artisan view:clear
COMPOSER_MEMORY_LIMIT=-1 composer require mpdf/mpdf flexyourrights/openpolice-extension

mv composer.json composer-orig.json
cp ../scripts-openpolice-extension/mac/composer.json composer.json
mv config/app.php config/app-orig.php
cp ../scripts-openpolice-extension/mac/config-app.php config/app.php

composer update
php artisan config:clear
php artisan route:clear
php artisan view:clear
echo "0" | php artisan vendor:publish --force

php artisan migrate --force
php artisan db:seed --force --class=OpenPoliceSeeder
if [ "$uploaddepts" == "y" ]; then
    php artisan db:seed --force --class=OpenPoliceDeptSeeder
    php artisan db:seed --force --class=OpenPoliceDeptSeeder2
    php artisan db:seed --force --class=OpenPoliceDeptSeeder3
    php artisan db:seed --force --class=OpenPoliceDeptSeeder4
fi
if [ "$uploadzips" == "y" ]; then
    php artisan db:seed --force --class=ZipCodeSeeder
    php artisan db:seed --force --class=ZipCodeSeeder2
    php artisan db:seed --force --class=ZipCodeSeeder3
    php artisan db:seed --force --class=ZipCodeSeeder4
fi
perl -pi -w -e "s/DB_HOST=127.0.0.1/DB_HOST=localhost/g" ./.env

php artisan config:clear
php artisan route:clear
php artisan view:clear
#curl http://$dir.local/css-reload
