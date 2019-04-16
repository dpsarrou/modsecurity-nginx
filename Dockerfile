ARG NGINX_VERSION=1.15.11

FROM alpine:3.9 as libmodsecurity-src
RUN apk add --no-cache git curl
RUN mkdir -p /usr/src && cd /usr/src \
	&& git clone https://github.com/SpiderLabs/ModSecurity \
	&& cd ModSecurity \
	&& git checkout v3/master \
	&& git submodule init \
	&& git submodule update

FROM alpine:3.9 as build
RUN apk add --no-cache \
		pcre-dev \
		libxml2-dev \
		git \
		libtool \
		automake \
		autoconf \
		g++ \
		flex \
		bison \
		yajl-dev \
		zlib-dev \
		make \
		libxslt-dev \
		linux-headers

# These are not really necessery
# RUN apk add --no-cache curl-dev geoip-dev libmaxminddb-dev lmdb-dev lmdb lua-dev doxygen

FROM build as libmodsecurity
COPY --from=libmodsecurity-src /usr/src/ModSecurity /usr/src/ModSecurity
WORKDIR /usr/src/ModSecurity
RUN sh build.sh && ./configure && make  && make install

FROM alpine:3.9 as nginx-src
ARG NGINX_VERSION

RUN apk add --no-cache gnupg1 curl
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $GPG_KEYS from $server"; \
		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
	&& rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& rm nginx.tar.gz \
	&& mv /usr/src/nginx-$NGINX_VERSION /usr/src/nginx

FROM build as modsecurity-nginx-src
WORKDIR /usr/src
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

FROM build as modsecurity-nginx-extension
COPY --from=libmodsecurity /usr/local/modsecurity /usr/local/modsecurity
COPY --from=modsecurity-nginx-src /usr/src/ModSecurity-nginx /usr/src/ModSecurity-nginx
COPY --from=nginx-src /usr/src/nginx /usr/src/nginx
WORKDIR /usr/src/nginx
RUN export MODSECURITY_INC="/usr/local/modsecurity/include/" && export MODSECURITY_LIB="/usr/local/modsecurity/lib/" && ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx \
	&& make modules \
	&& mv objs/ngx_http_modsecurity_module.so /usr/lib/ngx_http_modsecurity_module.so

FROM nginx:${NGINX_VERSION}-alpine
RUN apk add --no-cache yajl libstdc++
COPY --from=modsecurity-nginx-extension /usr/lib/ngx_http_modsecurity_module.so /etc/nginx/modules/
COPY --from=modsecurity-nginx-extension /usr/local/modsecurity/lib /usr/local/modsecurity/lib