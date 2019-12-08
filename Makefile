ifneq ($(lib_version),)
	_LIB_BUILD_ARGS := --build-arg LIB_VERSION=$(lib_version)
	_LIB_TAG := $(lib_tag)
else
	_LIB_TAG := v3-master-alpine
endif

ifneq ($(nginx_version),)
	_NGINX_VERSION :=$(nginx_version)
	_LIB_TAG :=$(lib_tag)
	_NGINX_TAG :=$(nginx_version)-alpine
	_OWASP_CRS_VERSION :=$(crs_version)
else
	_NGINX_VERSION :=1.17.6
	_LIB_TAG :=v3-master-alpine
	_NGINX_TAG :=${_NGINX_VERSION}-alpine
	_OWASP_CRS_VERSION :=3.2.0
endif
_NGINX_MODULE_BUILD_ARGS := --build-arg NGINX_VERSION=${_NGINX_VERSION} --build-arg LIB_TAG=${_LIB_TAG} --build-arg OWASP_CRS_VERSION=${_OWASP_CRS_VERSION}
_NGINX_BUILD_ARGS := --build-arg NGINX_VERSION=$(_NGINX_VERSION)

usage:
	@echo "Usage:"
	@echo "make libmodsecurity {lib_version=} {lib_tag=}"
	@echo "make module {nginx_version=} {lib_tag=}"
	@echo "make nginx {nginx_version=} {lib_tag=}"

libmodsecurity:
	@docker build . -f libmodsecurity.docker ${_LIB_BUILD_ARGS} -t cminor/libmodsecurity:${_LIB_TAG}
	@docker push cminor/libmodsecurity:${_LIB_TAG}

latest-libmodsecurity: libmodsecurity
	@docker tag cminor/libmodsecurity:${_LIB_TAG} cminor/libmodsecurity:latest
	@docker push cminor/libmodsecurity:latest

module:
	@docker build . -f modsecurity-module.docker ${_NGINX_MODULE_BUILD_ARGS} -t cminor/modsecurity-crs-module:${_NGINX_TAG}
	@docker push cminor/modsecurity-crs-module:${_NGINX_TAG}

latest-module: module
	@docker tag cminor/modsecurity-crs-module:${_NGINX_TAG} cminor/modsecurity-crs-module:latest
	@docker push cminor/modsecurity-crs-module:latest

nginx:
	@docker build . -f nginx.docker ${_NGINX_BUILD_ARGS} -t cminor/nginx-modsecurity-crs:${_NGINX_TAG}
	@docker push cminor/nginx-modsecurity-crs:${_NGINX_TAG}

latest-nginx: nginx
	@docker tag cminor/nginx-modsecurity-crs:${_NGINX_TAG} cminor/nginx-modsecurity-crs:latest
	@docker push cminor/nginx-modsecurity-crs:latest

tag:
	@git tag ${_NGINX_VERSION}-modsec${_LIB_VERSION}-crs{_CRS_VERSION}-alpine