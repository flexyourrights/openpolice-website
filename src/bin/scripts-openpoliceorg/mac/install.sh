#!/bin/bash
set +x
echo '================================='
echo 'Local OpenPolice.org Installation'
echo '-------------------------------------'
echo 'To be run in code folder of Homestead'
echo '====================================='
echo ''
read -p $'What is the directory for this local OpenPolice.org installation (relative to current folder)?\nIf it exists, it will be deleted for a fresh install.\n(e.g. myopenpolice)\n' dir
echo ''
read -p $'What is the database name for this installation, already created in Homestead?\n(e.g. myopenpolice)\n' dbname
echo ''

if [ $# -eq 1 ]; then
    set -x
fi

if [ ! -f scripts-openpoliceorg/mac/helpers-installed.txt ]; then
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
    echo 'Helpers installed.' >> scripts-openpoliceorg/mac/helpers-installed.txt
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
cp ../scripts-openpoliceorg/mac/op.env txt.env
perl -pi -w -e "s/DB_DATABASE=myopenpolice/DB_DATABASE=$dbname/g" txt.env
perl -pi -w -e "s/myopenpolice.local/$dir.local/g" txt.env
mv txt.env .env
php artisan key:generate
php artisan config:cache
php artisan route:cache
php artisan view:cache
COMPOSER_MEMORY_LIMIT=-1 composer require laravel/ui paragonie/random_compat
php artisan ui vue --auth
composer require mpdf/mpdf
composer require rockhopsoft/survloop "0.3.*"
composer require flexyourrights/openpolice "0.3.*"

mv composer.json composer-orig.json
cp ../scripts-openpoliceorg/mac/composer.json composer.json
mv config/app.php config/app-orig.php
cp ../scripts-openpoliceorg/mac/config-app.php config/app.php

composer update
composer dump-autoload
echo "0" | php artisan vendor:publish --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

#DBKEY='\\Illuminate\\Support\\Facades\\DB'
#perl -pi -w -e "s/$DBKEY::statement('SET SESSION sql_require_primary_key=0'); / /g" database/migrations/*.php
php artisan migrate --force
php artisan db:seed --force --class=OpenPoliceSeeder
php artisan db:seed --force --class=OpenPoliceDeptSeeder
php artisan db:seed --force --class=OpenPoliceDeptSeeder2
php artisan db:seed --force --class=OpenPoliceDeptSeeder3
php artisan db:seed --force --class=OpenPoliceDeptSeeder4
php artisan db:seed --force --class=ZipCodeSeeder
php artisan db:seed --force --class=ZipCodeSeeder2
php artisan db:seed --force --class=ZipCodeSeeder3
php artisan db:seed --force --class=ZipCodeSeeder4

php artisan config:cache
php artisan route:cache
php artisan view:cache
composer dump-autoload
curl http://$dir.local/css-reload
