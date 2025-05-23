# syntax=docker/dockerfile:1
#checkov:skip=CKV_DOCKER_2
#checkov:skip=CKV_DOCKER_3
FROM golang:1.24-alpine

ENV GOTOOLCHAIN=local
ENV CFLAGS="-ggdb3"
ENV PHPIZE_DEPS="\
	autoconf \
	dpkg-dev \
	file \
	g++ \
	gcc \
	libc-dev \
	make \
	pkgconfig \
	re2c"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache \
	$PHPIZE_DEPS \
	argon2-dev \
	brotli-dev \
	curl-dev \
	oniguruma-dev \
	readline-dev \
	libsodium-dev \
	sqlite-dev \
	openssl-dev \
	libxml2-dev \
	zlib-dev \
	bison \
	nss-tools \
	# file watcher
	libstdc++ \
	linux-headers \
	# Dev tools \
	git \
	clang \
	cmake \
	llvm \
	gdb \
	valgrind \
	neovim \
	zsh \
	libtool && \
	echo 'set auto-load safe-path /' > /root/.gdbinit

WORKDIR /usr/local/src/php
RUN git clone --branch=PHP-8.4 https://github.com/php/php-src.git . && \
	# --enable-embed is only necessary to generate libphp.so, we don't use this SAPI directly
	./buildconf --force && \
	./configure \
		--enable-embed \
		--enable-zts \
		--disable-zend-signals \
		--enable-zend-max-execution-timers \
		--enable-debug && \
	make -j"$(nproc)" && \
	make install && \
	ldconfig /etc/ld.so.conf.d && \
	cp php.ini-development /usr/local/lib/php.ini && \
	echo "zend_extension=opcache.so" >> /usr/local/lib/php.ini && \
	echo "opcache.enable=1" >> /usr/local/lib/php.ini && \
	php --version

# Install e-dant/watcher (necessary for file watching)
WORKDIR /usr/local/src/watcher
RUN git clone https://github.com/e-dant/watcher . && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
	cmake --build build/ && \
	cmake --install build

WORKDIR /go/src/app
COPY . .

WORKDIR /go/src/app/caddy/frankenphp
RUN go build

WORKDIR /go/src/app
CMD [ "zsh" ]
