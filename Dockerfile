FROM debian:buster

# 时区设置
ARG TIMEZONE="Asia/Shanghai"
# COPY ./sources.list /etc/apt/sources.list
RUN rm -rf /etc/localtime && \
    ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo ${TIMEZONE} > /etc/timezone && \
    # 创建相关的目录
    mkdir -p /workspace/app /workspace/etc /workspace/data/mysql /workspace/data/redis /workspace/src /workspace/www \
    /workspace/log/php /workspace/log/nginx /workspace/log/mysql /workspace/log/redis /workspace/run/mysql \
    /run/sshd && \
    # 创建 www 和 mysql 用户
    groupadd mysql && useradd -r -gmysql -M -s/bin/false mysql && \
    groupadd www && useradd -r -gwww -M -s/bin/false www && \
    # 目录权限
    chown -R mysql:mysql /workspace/data/mysql && \
    chown -R mysql:mysql /workspace/log/mysql && \
    chmod -R 777 /workspace/run && \
    chown -R mysql:mysql /workspace/run/mysql && \
    # 安装依赖
    apt-get update && apt-get install -y --no-install-recommends apt-transport-https ca-certificates apt-utils ssh zsh \
    wget curl git vim autoconf dpkg-dev g++ gcc make libaio1 libnuma1 libtinfo5 libc-dev pkg-config xz-utils libgd-dev \
    libargon2-dev libcurl4-openssl-dev libedit-dev libsodium-dev libsqlite3-dev libssl-dev libxml2-dev libxslt1-dev \
    zlib1g-dev libsystemd-dev libbz2-dev libenchant-dev libjpeg62-turbo-dev libpng-dev libfreetype6-dev libwebp-dev \
    libsnmp-dev libperl-dev libzip-dev libgeoip-dev libjemalloc-dev supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    # 安装 oh-my-zsh
    sh -c "$(wget https://raw.github.com/poplary/oh-my-zsh/master/tools/install.sh -O -)"

# 指定版本
ARG FREETYPE_VERSION="2.10.1"
ARG PHP_VERSION="7.3.8"
ARG NGINX_VERSION="1.16.1"
ARG REDIS_VERSION="5.0.5"
ARG MYSQL_VERSION="8.0.17"
ARG PHP_REDIS_VERSION="5.0.2"
ARG SWOOLE_VERSION="4.4.4"

# 下载并解压
RUN wget https://nchc.dl.sourceforge.net/project/freetype/freetype2/${FREETYPE_VERSION}/freetype-${FREETYPE_VERSION}.tar.gz \
    -O /workspace/src/freetype-${FREETYPE_VERSION}.tar.gz && \
    tar -xzvf /workspace/src/freetype-${FREETYPE_VERSION}.tar.gz -C /workspace/src && \
    # 下载解压 PHP
    wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz \
    -O /workspace/src/php-${PHP_VERSION}.tar.gz && \
    tar -xzvf /workspace/src/php-${PHP_VERSION}.tar.gz -C /workspace/src && \
    # 下载解压 Nginx
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    -O /workspace/src/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzvf /workspace/src/nginx-${NGINX_VERSION}.tar.gz -C /workspace/src && \
    # 下载 Redis
    wget http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz \
    -O /workspace/src/redis-${REDIS_VERSION}.tar.gz && \
    tar -xzvf /workspace/src/redis-${REDIS_VERSION}.tar.gz -C /workspace/src && \
    # 下载解压 MySQL
    wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.xz \
    -O /workspace/src/mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.xz && \
    tar -xJvf /workspace/src/mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.xz -C /workspace/src && \
    mv /workspace/src/mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64 /workspace/app/mysql && \
    # 下载解压 phpredis
    wget https://github.com/phpredis/phpredis/archive/${PHP_REDIS_VERSION}.tar.gz \
    -O /workspace/src/phpredis-${PHP_REDIS_VERSION}.tar.gz && \
    tar xzvf /workspace/src/phpredis-${PHP_REDIS_VERSION}.tar.gz -C /workspace/src && \
    # 下载解压 swoole
    wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz \
    -O /workspace/src/swoole-v${SWOOLE_VERSION}.tar.gz && \
    tar xzvf /workspace/src/swoole-v${SWOOLE_VERSION}.tar.gz -C /workspace/src

# 安装 freetype
RUN cd /workspace/src/freetype-${FREETYPE_VERSION} && \
    ./configure --prefix=/usr/local --enable-freetype-config && make && make install && \
    # 安装 PHP
    cd /workspace/src/php-${PHP_VERSION} && \
    ./configure --prefix=/workspace/app/php \
    --bindir=/usr/local/bin \
    --sbindir=/usr/local/sbin \
    --enable-fpm \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-fpm-systemd \
    --enable-debug \
    --with-config-file-path=/workspace/etc/php \
    --with-config-file-scan-dir=/workspace/etc/php/conf.d \
    --with-openssl \
    --with-zlib \
    --enable-bcmath \
    --with-bz2 \
    --enable-calendar \
    --with-curl \
    --with-enchant \
    --enable-exif \
    --with-pcre-dir=/usr \
    --enable-ftp \
    --with-gd \
    --with-png-dir=/usr \
    --with-jpeg-dir=/usr \
    --with-freetype-dir=/usr/local \
    --with-webp-dir=/usr \
    --with-gettext \
    --with-mhash \
    --enable-intl \
    --enable-mbstring \
    --with-onig \
    --with-mysqli=mysqlnd \
    --enable-pcntl \
    --with-pdo-mysql=mysqlnd \
    --with-libedit \
    --with-readline \
    --enable-shmop \
    --with-snmp \
    --enable-soap \
    --enable-sockets \
    --with-password-argon2 \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --with-xsl \
    --enable-zip \
    --with-libzip \
    --enable-mysqlnd \
    --enable-shared=no \
    --enable-static=yes \
    --with-sodium && \
    make && make install && \
    # 安装 Nginx
    cd /workspace/src/nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/workspace/app/nginx \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/workspace/etc/nginx/nginx.conf \
    --pid-path=/workspace/run/nginx.pid \
    --lock-path=/workspace/run/nginx.lock \
    --user=www \
    --group=www \
    --error-log-path=/workspace/log/nginx/error.log \
    --http-log-path=/workspace/log/nginx/access.log \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_geoip_module \
    --with-http_gzip_static_module \
    --with-stream \
    --with-debug && \
    make && make install && \
    # 安装 Redis
    cd /workspace/src/redis-${REDIS_VERSION} && \
    make MALLOC=jemalloc && \
    make install && \
    mv /workspace/src/redis-${REDIS_VERSION} /workspace/app/redis && \
    # 安装 MySQL
    cd /workspace/app/mysql && \
    ./bin/mysqld --initialize-insecure --user=mysql --basedir=/workspace/app/mysql --datadir=/workspace/data/mysql && \
    /bin/ln -s /workspace/app/mysql/bin/mysql /usr/local/bin && \
    /bin/ln -s /workspace/app/mysql/bin/mysqld /usr/local/bin && \
    /bin/ln -s /workspace/app/mysql/bin/mysqldump /usr/local/bin && \
    # 安装 phpredis
    cd /workspace/src/phpredis-${PHP_REDIS_VERSION} && \
    /usr/local/bin/phpize && \
    ./configure \
    && make && make install && \
    # 安装 swoole
    cd /workspace/src/swoole-src-${SWOOLE_VERSION} && \
    /usr/local/bin/phpize && \
    ./configure --enable-openssl --enable-sockets --enable-http2 --enable-mysqlnd && \
    make && make install && \
    # 删除所有源文件
    rm -rf /workspace/src/* && \
    rm -rf /etc/mysql && \
    apt-get autoremove && \
    apt-get autoclean

# 复制配置文件
COPY ./conf/php /workspace/etc/php
COPY ./conf/nginx /workspace/etc/nginx
COPY ./conf/mysql /etc/mysql
COPY ./conf/redis /workspace/etc/redis
COPY ./supervisor /etc/supervisor/conf.d
COPY ./ssh/docker.hub /root/.ssh/authorized_keys

RUN chmod 644 /etc/mysql/my.cnf && \
    chmod 600 /root/.ssh/authorized_keys

WORKDIR /root

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
