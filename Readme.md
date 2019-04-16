# ModSecurity for Nginx

Reusable components of ModSecurity for nginx alpine images.

Images:
- cminor/libmodsecurity:v3-master-alpine

    This image contains the compiled `libmodsecurity` library in Alpine Linux with all dependencies.

    If you are building a modsecurity module, such as modsecurity-nginx, you can use this image to copy the compiled library instead of having  to spend considerable amount of time installing the dependencies and compilining it yourself.

    ## Usage
    ```
    COPY --from=cminor/libmodsecurity:v3-master-alpine /usr/local/modsecurity /usr/local/modsecurity
    ```
- cminor/modsecurity-crsmodule:1.15.11-alpine

    The image contains the modsecurity-nginx module along with the owasp crs rule set.
    Normally to integrate nginx with modsecurity you need to compile the `libmodsecurity` library and then compile the `modsecurity-nginx` module
    using the source code of `nginx`. This is a time consuming process but this image will save you that time because it takes advantage of
    the docker layer caching and the precompiled `cminor/libmodsecurity` image. There is one caveat however. The `modsecurity-nginx` module version
    needs to match your nginx version. I will try to keep up with the updates but if you have the time to create an automated solution, a PR would be very much appreciated. Alternatively you can build the module yourself easily using the `Makefile` and the `dockerfile` of this repo.

    ## Usage
    At your `nginx` (alpine based) dockerfile copy the module files:
    ```
    # Install required runtime packages (mandatory due to libmodsecurity)
    RUN apk add --no-cache yajl libstdc++ curl lua libmaxminddb
    # Grab the modsecurity-nginx module files
    COPY --from=cminor/modsecurity-crsmodule:1.15.11-alpine /etc/nginx/modsec /etc/nginx/modsec
    ```
    load_module /etc/nginx/modsec/ngx_http_modsecurity_module.so;
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/modsec.conf;
    ```

- cminor/nginx-modsecurity-crs:1.15.11-alpine
    The lightweight `nginx` webserver with the `modsecurity-ngin` module and the `owasp crs` ruleset in place.
    If you are not building your own custom nginx image, you can quickly start with this prebuilt `nginx`+`modsecurity`+`owasp crs`
    alpine based image. Everything is preinstalled and the image extends from  the official `nginx:*-alpine` image.
    However you need to enable `modsecurity` in your `nginx.conf` (not included). Either provide your own `nginx.conf` and replace
    the stock `/etc/nginx/nginx.conf` or extend this image and append the required lines to activate `modsecurity`.

    ## Usage:
    Either extend this image and edit the existing `/etc/nginx/nginx.conf` or share/copy your own. In any case you just need to add the following lines to activate modsecurity:
    ```
    load_module /etc/nginx/modsec/ngx_http_modsecurity_module.so;
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/modsec.conf;
    ```

# Building the images

Use the provided `Makefile` to build the images. Change the versions to build
one specific to your needs.

### Note
Variables enclosed in `{}` are optional.

## libmodsecurity
```
make libmodsecurity {lib_version=v3/master} {lib_tag=v3-master-alpine}
```

## ModSecurity-nginx module
The image can easily be built with:
```
make module {nginx_version=1.15.11} {lib_tag=v3-master-alpine}
```

## Nginx with ModSecurity and OWASP OCR
```
make nginx {nginx_version=1.15.11}
```