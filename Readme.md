# ModSecurity-Nginx

A docker image with a precompiled version of nginx:alpine with the ModSecurity-nginx module.

# Usage

## Use the image directly
Create a dockerfile and extend this image with your own configuration.

```
FROM cminor/modsecurity-nginx:1.15.11-alpine
# your stuff goes here
```

## Use the precompiled ModSecurity-nginx module
If you want to add modsecurity 3.x to your own nginx image without going through the trouble of compilining the libmodsecurity library, the nginx module, and nginx yourself (which is highly recommended if you want to be specific about the functionality you want to include, but very time/resource consuming)m
just add the below lines to your Dockerfile and load the module in your nginx.conf.

In your `Dockerfile`:
```
FROM nginx:1.15.11-alpine
# Required runtime packages for modsecurity
RUN apk add --no-cache yajl libstdc++
COPY --from=cminor/modsecurity-nginx:1.15.11-alpine /usr/lib/ngx_http_modsecurity_module.so /etc/nginx/modules/
COPY --from=cminor/modsecurity-nginx:1.15.11-alpine /usr/local/modsecurity/lib /usr/local/modsecurity/lib
```

In your `nginx.conf`
```
load_module modules/ngx_http_modsecurity_module.so;
```

## Notes
Modsecurity module needs to be compiled for the specific version of
your nginx instance. Use the appropriate version. I will try to keep the image up-to-date with each version of nginx.
If you think you have time to automate this process, please open a PR, I would be more than happy to discuss it with you.

# Building the image
The image can easily be built with:
```
docker build . --build-arg NGINX_VERSION=1.15.11 -t cminor/modsecurity-nginx:1.15.11-alpine

# optionally push the image
docker push cminor/modsecurity-nginx:1.15.11-alpine
```

Change the version argument appropriately to build for other versions