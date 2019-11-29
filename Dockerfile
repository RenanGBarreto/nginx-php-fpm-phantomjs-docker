########################################################
# Dockerfile for NGINX + PHP7-FPM + Phantom and some Extensions
########################################################
# How to run
#  - docker run -d nginx-php-fpm-phantomjs-docker
# How to build
#  - docker build -t nginx-php-fpm-phantomjs-docker -f Dockerfile .
########################################################
# SERVICES AND LIBS INSTALLED:
# - Nginx
# - PHP 7.3 (FPM)
# - composer
# - php-mongodb extension
# - php-mysql extension
# - tesseract-ocr
# - phantomjs
# - wkhtmltopdf
########################################################
# This dockerfile was created based on:
# - https://hub.docker.com/_/debian
########################################################

FROM debian:9-slim

MAINTAINER Renan Gomes <email@renangomes.com>

# Install PHP7.3+Extensions and NGINX
RUN apt-get update \
  && apt-get install -y gnupg1 apt-transport-https ca-certificates wget git zip unzip  wkhtmltopdf \
  && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
  && echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list \
  && apt-get update \
  && apt-get install -y wget \
  && wget -O /etc/ssl/certs/curl-ca-bundle.crt https://curl.haxx.se/ca/cacert.pem \
  && chmod 777 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/curl-ca-bundle.crt \  
  && chown www-data:www-data /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/curl-ca-bundle.crt \
  && apt-get install -y -qq nano curl tesseract-ocr tesseract-ocr-eng nginx php7.3 php7.3-curl php7.3-soap php7.3-json php7.3-mbstring php7.3-mysql php7.3-simplexml php7.3-odbc php7.3-fpm php7.3-mongodb php7.3-gd \
  && phpenmod curl json mbstring mysql odbc mongodb gd simplexml soap \
  && openssl dhparam -out /etc/ssl/certs/ssl-cert-snakeoil.pem 2048 && chmod -R 600 /etc/ssl/certs/* \
  && sed -i "s|;*clear_env\s*=\s*.*|clear_env = no|g" /etc/php/7.3/fpm/pool.d/www.conf \
  && rm -Rf /var/www/* && mkdir /run/php/ \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && apt-get clean -qq \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
  
# Copy the default nginx settings
COPY default /etc/nginx/sites-enabled/
  
# Install PhantomJs
RUN mkdir /root/phantomjs \
  && curl -kLS https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 -o /root/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
  && tar xvjf /root/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /root/phantomjs/ \
  && chmod a+x /root/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs \
  && ln -s /root/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs
  
# Tweaks to give Nginx/PHP write permissions to the app
ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20
ENV DOCKER_MACHINE_ID 1000
ENV DOCKER_MACHINE_GID 50
RUN usermod -u ${DOCKER_MACHINE_ID} www-data && \
    usermod -G staff www-data
RUN groupmod -g $(($DOCKER_MACHINE_GID + 10000)) $(getent group $DOCKER_MACHINE_GID | cut -d: -f1)
RUN groupmod -g ${DOCKER_MACHINE_GID} staff

# Create the execution binary for the entrypoint
RUN echo "#\!/bin/sh\n cd /var/www; composer --no-plugins --no-scripts install; chown www-data:www-data /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/curl-ca-bundle.crt; chmod 777 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/curl-ca-bundle.crt; php-fpm7.3; nginx -g 'daemon off;'" > /run/startup.sh && chmod a+x /run/startup.sh

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# make sure the user can write in tmp
RUN chmod 777 /tmp
RUN chmod 777 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/curl-ca-bundle.crt
RUN chown www-data:www-data /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/curl-ca-bundle.crt

## Change the work dir the the code dir
WORKDIR /var/www

VOLUME ["/var/www", "/var/log/nginx", "/etc/nginx/conf.d/"]

STOPSIGNAL SIGTERM

EXPOSE 80

CMD ["/bin/sh", "-c", "/run/startup.sh"]

ENTRYPOINT ["/bin/sh", "-c", "/run/startup.sh"]