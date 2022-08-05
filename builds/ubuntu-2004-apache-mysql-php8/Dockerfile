#Download base image ubuntu 20.04
FROM ubuntu:20.04

# LABEL about the custom image
LABEL maintainer="michael.toriola@finixio.com"
LABEL version="0.1"
LABEL description="Custom docker image for php and apache"

ARG APP_ENV
ARG APP_USER

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive

# Update Ubuntu Software repository
RUN apt update

# Install nginx, php-fpm and supervisord from ubuntu repository
RUN apt install -y zip git unzip curl apache2 supervisor software-properties-common vim
RUN add-apt-repository -y ppa:ondrej/php
RUN apt update
RUN apt install -y php8.0 libapache2-mod-php8.0 php8.0-curl php8.0-mysql php8.0-mysqli php8.0-mbstring \
    php8.0-xml php8.0-zip php8.0-gd php8.0-imagick

RUN if [ "$APP_ENV" = "dev" ]; then \
    apt install -y php8.0-xdebug;  \
    fi
RUN rm -rf /var/lib/apt/lists/*
RUN apt clean

#Define the ENV variable
ENV apache_vhost_available /etc/apache2/sites-available/default.conf
ENV apache_vhost_enabled /etc/apache2/sites-enabled/default
ENV supervisor_conf /etc/supervisor/supervisord.conf

# Enable PHP-fpm on nginx virtualhost configuration
COPY ./apache/default ${apache_vhost_available}
COPY ./apache/default ${apache_vhost_enabled}

RUN if [ -f /etc/apache2/sites-available/000-default.conf ]; then \
    a2dissite 000-default.conf;  \
    fi
RUN if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then \
    a2dissite 000-default.conf;  \
    fi

RUN a2ensite default.conf
RUN a2enmod rewrite

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Copy supervisor configuration
COPY supervisord.conf ${supervisor_conf}
# Copy start.sh script and define default command for the container
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /var/www/html

#Web docs
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /run/php

# Volume configuration
VOLUME ["/etc/apache/sites-enabled", "/var/log/apache2", "/var/www/html"]

#USER truvoice

CMD ["/start.sh"]

# Expose Port for the Application
EXPOSE 80 443
