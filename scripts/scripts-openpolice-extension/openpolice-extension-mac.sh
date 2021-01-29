#!/bin/bash
set +x
echo '==============================='
echo 'Homestead Survloop Installation'
#echo '-------------------------------'
#echo 'To be run under "sudo su"'
if [ $# -eq 0 ]; then
    echo '-------------------------------'
    echo 'To run this with all commands printing to the screen,'
    echo 'cancel this (Ctrl+C), and re-run this script with any parameter:'
    echo '# bash ./install-scripts/homestead/survloop/survloop.sh debug'
fi
echo '==============================='
echo ''
read -p $'What is the directory for this local Survloop installation (relative to current folder)?\nIf it exists, it will be deleted for a fresh install.\n(e.g. survloop)\n' dir
echo ''
read -p $'Do you want a standalone Survloop installation?\nIf not, you need a package which extends the Survloop engine.\n("y" or "n")\n' nopckg
echo ''
if [ "$nopckg" == "n" ]; then
    read -p $'What is the vender path for package vendor?\n(e.g. rockhopsoft/survlooporg)\n' pckgpath
    echo ''
    read -p $'What is the your package vendor name?\n(e.g. RockHopSoft)\n' classvend
    echo ''
    read -p $'What is the class name of your package?\n(e.g. SurvloopOrg)\n' classname
    echo ''
fi
echo '--'
echo '----'
echo '--------'
echo 'Survloop Installation Settings'
echo '------------------------------'
echo "New Directory:     $dir"
if [ "$nopckg" == "n" ]; then
    echo "Package Class:     $classvend\\$classname"
    echo "Package Directory: $pckgpath"
fi
echo '=============================='

if [ $# -eq 1 ]; then
    set -x
fi

if [ ! -f install-scripts/src/homestead/helpers-installed.txt ]; then
    bash install-scripts/src/homestead/survloop-mac-run-once.sh

    sed -i "s/INSTDIR='survloop'/INSTDIR='$dir'/g" install-scripts/src/homestead/samples/*.sh
    sed -i "s/SUPUSER='survuser'/SUPUSER='$SUPUSER'/g" install-scripts/src/homestead/samples/*.sh
    sed -i "s/pckgpath='rockhopsoft\/survlooporg'/pckgvend='$pckgvend'/g" install-scripts/src/homestead/samples/*.sh
    sed -i "s/classname='SurvloopOrg'/classname='$classname'/g" install-scripts/src/homestead/samples/*.sh
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
if [ -d "./$dir/orig.env" ]; then
    rm -f ./$dir/orig.env
fi
mv ./$dir/.env ./$dir/orig.env
cp ./install-scripts/src/homestead/samples/survloop.env $dir/env.txt
if [ "$NOPCKG" == "n" ]; then
    perl -pi -w -e "s/APP_NAME=Survloop/APP_NAME=$classname/g" $dir/env.txt
    perl -pi -w -e "s/survloop.local/$dir.local/g" $dir/env.txt
    perl -pi -w -e "s/DB_DATABASE=survloop/DB_DATABASE=$dir/g" $dir/env.txt
fi
mv ./$dir/env.txt ./$dir/.env
echo 'Laravel environment file updated.'
cd $dir
php artisan key:generate
#php artisan cache:clear
COMPOSER_MEMORY_LIMIT=-1 composer require laravel/ui paragonie/random_compat mpdf/mpdf rockhopsoft/survloop
php artisan ui vue --auth
echo ''
echo '--'
echo '----'
echo '--------'
if [ "$NOPCKG" == "n" ]; then
    echo 'Install Survloop & Extension Package'
    echo '===================================='
    composer require $pckgpath
    cp -f ../install-scripts/src/samples/laravel-composer-package.json composer.json.txt
    perl -pi -w -e "s/rockhopsoft\/survlooporg/$pckgpath/g" composer.json.txt
    perl -pi -w -e "s/RockHopSoft\/SurvloopOrg/$classvend\/$classname/g" composer.json.txt
    perl -pi -w -e "s/SurvloopOrg/$classname/g" composer.json.txt
    mv composer.json composer.json-orig
    mv composer.json.txt composer.json
    mv config/app.php config/app.orig.php
    cp -f ../install-scripts/src/samples/laravel-config-app-package.php config/app.php
    perl -pi -w -e "s/RockHopSoft\/SurvloopOrg/$classvend\/$classname/g" config/app.php
    perl -pi -w -e "s/SurvloopOrg/$classname/g" config/app.php
    composer update
    php artisan optimize:clear
else
    echo 'Install Survloop'
    echo '================'
    mv composer.json composer.json-orig
    cp -f ../install-scripts/src/samples/laravel-composer.json composer.json
    composer update
    php artisan optimize:clear
    mv config/app.php config/app.orig.php
    cp -f ../install-scripts/src/samples/laravel-config-app.php config/app.php
fi
composer dump-autoload
echo "0" | php artisan vendor:publish --force
php artisan optimize:clear
composer dump-autoload
DBKEY='\\Illuminate\\Support\\Facades\\DB'
perl -pi -w -e "s/$DBKEY::statement('SET SESSION sql_require_primary_key=0'); / /g" database/migrations/*.php
php artisan migrate --force
php artisan db:seed --force --class=SurvloopSeeder
php artisan db:seed --force --class=ZipCodeSeeder
php artisan db:seed --force --class=ZipCodeSeeder2
php artisan db:seed --force --class=ZipCodeSeeder3
php artisan db:seed --force --class=ZipCodeSeeder4
if [ "$NOPCKG" == "n" ]; then
    echo "yes" | php artisan db:seed --force --class=$classname
fi
#chown -R www-data:www-data storage bootstrap/cache resources/views database app/Models
php artisan optimize:clear
composer dump-autoload
curl http://$dir.local/css-reload
