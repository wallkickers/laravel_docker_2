#!/bin/bash

DATE=`date "+%Y-%m-%d"`
sudo -u nginx touch /var/log/nginx/access.log
sudo -u nginx touch /var/log/nginx/error.log
touch /var/log/php-fpm/error.log
sudo -u nginx touch /var/www/html/storage/logs/laravel-${DATE}.log
mkdir -p /var/www/html/storage/logs/batch && sudo -u nginx touch /var/www/html/storage/logs/batch/batch-${DATE}.log

tail -F /var/log/nginx/access.log  | stdbuf -i0 -o0 -e0 ccze -A | rtail -h monitor.docker.local -p 10084 -m --no-parse-date --name "[nginx]access.log" &
tail -F /var/log/nginx/error.log   | stdbuf -i0 -o0 -e0 ccze -A | rtail -h monitor.docker.local -p 10084 -m --no-parse-date --name "[nginx]error.log" &
tail -F /var/log/php-fpm/error.log | stdbuf -i0 -o0 -e0 ccze -A | rtail -h monitor.docker.local -p 10084 -m --no-parse-date --name "[php-fpm]error.log" &
tail -F /var/www/html/storage/logs/laravel-${DATE}.log | stdbuf -i0 -o0 -e0 ccze -A | rtail -h monitor.docker.local -p 10084 -m --no-parse-date --name "[laravel]laravel.log" &
tail -F /var/www/html/storage/logs/batch/batch-${DATE}.log | stdbuf -i0 -o0 -e0 ccze -A | rtail -h monitor.docker.local -p 10084 -m --no-parse-date --name "[laravel]batch.log" &

[ ! -f /var/www/html/.env ] && cp /var/www/html/.env.local /var/www/html/.env

composer install
[ "$(php artisan migrate:status)" = 'No migrations found.' ] && php artisan migrate:refresh --seed && php artisan db:seed --class=TestDataSeeder
php artisan ide-helper:generate
php artisan ide-helper:meta
php artisan ide-helper:models -N

npm install
npm run watch-poll &

exit 0
