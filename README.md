# Docker images for common NGINX + PHP7 + PhantomJS Services

Docker image for working with nginx, php7-fpm, php mongo extensions, phantomJS and tesseract OCR.

## Software installed:
- Nginx
- PHP 7 (FPM)
- composer (from php)
- php-mongodb extension
- php-mysql extension
- tesseract-ocr
- phantomjs

## How to run
``` docker-compose up -d renangbarreto/nginx-php-fpm-phantomjs-docker ```

## How to build
``` docker-compose build -t renangbarreto/nginx-php-fpm-phantomjs-docker -f Dockerfile . ```

## Volumes

/var/www

## Ports

80