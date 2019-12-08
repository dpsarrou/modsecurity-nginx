ARG NGINX_VERSION=1.17.6

FROM cminor/modsecurity-crs-module:${NGINX_VERSION}-alpine as module

FROM nginx:${NGINX_VERSION}-alpine
COPY --from=module /etc/nginx/modsec /etc/nginx/modsec
RUN apk add --no-cache yajl libstdc++ curl lua libmaxminddb