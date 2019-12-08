ARG NGINX_VERSION=1.15.12
ARG LIB_TAG=v3-master-alpine

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

RUN apk add --no-cache curl-dev geoip-dev libmaxminddb-dev lmdb-dev lmdb lua-dev doxygen

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

FROM cminor/libmodsecurity:${LIB_TAG} as libmodsecurity

FROM build as modsecurity-nginx-extension
COPY --from=libmodsecurity /usr/local/modsecurity /etc/nginx/modsec/modsecurity
COPY --from=modsecurity-nginx-src /usr/src/ModSecurity-nginx /usr/src/ModSecurity-nginx
COPY --from=nginx-src /usr/src/nginx /usr/src/nginx
WORKDIR /usr/src/nginx
RUN export MODSECURITY_INC="/etc/nginx/modsec/modsecurity/include/" && export MODSECURITY_LIB="/etc/nginx/modsec/modsecurity/lib/" && ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx \
	&& make modules \
	&& mv objs/ngx_http_modsecurity_module.so /etc/nginx/modsec/ngx_http_modsecurity_module.so

FROM alpine:3.9 as owasp-crs
ARG OWASP_CRS_VERSION=3.2.0
RUN apk add --no-cache curl
WORKDIR /usr/src
RUN curl -fSL https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v${OWASP_CRS_VERSION}.tar.gz -o owasp-crs.tar.gz \
    && tar -xzvf owasp-crs.tar.gz && mv /usr/src/owasp-modsecurity-crs-${OWASP_CRS_VERSION} /usr/src/owasp-modsecurity-crs
RUN cp /usr/src/owasp-modsecurity-crs/crs-setup.conf.example /usr/src/owasp-modsecurity-crs/crs-setup.conf

FROM alpine:3.9
COPY --from=modsecurity-nginx-extension /etc/nginx/modsec/ /etc/nginx/modsec
COPY --from=owasp-crs /usr/src/owasp-modsecurity-crs /etc/nginx/modsec/owasp-modsecurity-crs
COPY modsec/modsec.conf /etc/nginx/modsec/