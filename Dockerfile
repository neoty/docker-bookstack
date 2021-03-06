FROM lsiobase/nginx:3.9

# set version label
ARG 0.27.4
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="homerr"

# package versions
ARG BOOKSTACK_RELEASE

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache  \
	curl \
	tar \
	netcat-openbsd \
    php7-opcache \
	php7-ctype \
	php7-curl \
	php7-dom \
	php7-gd \
	php7-ldap \
	php7-mbstring \
	php7-memcached \
	php7-mysqlnd \
	php7-openssl \
	php7-pdo_mysql \
	php7-phar \
	php7-simplexml \
	php7-tidy \
	php7-tokenizer && \
 echo "**** configure php-fpm ****" && \
 sed -i 's/;clear_env = no/clear_env = no/g' /etc/php7/php-fpm.d/www.conf && \
 echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php7/php-fpm.conf && \
 echo "**** fetch bookstack ****" && \
 mkdir -p\
	/var/www/html && \
 if [ -z ${BOOKSTACK_RELEASE+x} ]; then \
 BOOKSTACK_RELEASE=$(curl -sX GET "https://api.github.com/repos/bookstackapp/bookstack/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 /tmp/bookstack.tar.gz -L \
    "https://github.com/BookStackApp/BookStack/archive/${BOOKSTACK_RELEASE}.tar.gz" && \
 tar xf \
 /tmp/bookstack.tar.gz -C \
	/var/www/html/ --strip-components=1 && \
 echo "**** install  composer ****" && \
 cd /tmp && \
 curl -sS https://getcomposer.org/installer | php && \
 mv /tmp/composer.phar /usr/local/bin/composer && \
 echo "**** install composer dependencies ****" && \
 composer install -d /var/www/html/ && \
 echo "**** cleanup ****" && \
 rm -rf \
	/root/.composer \
	/tmp/*

RUN apk add nodejs nodejs-npm
RUN npm install -g minify
RUN minify /var/www/html/public/dist/styles.css > /var/www/html/public/dist/styles.minify.css
RUN mv /var/www/html/public/dist/styles.minify.css /var/www/html/public/dist/styles.css
RUN npm uninstall -g minify
RUN apk del nodejs nodejs-npm
# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
