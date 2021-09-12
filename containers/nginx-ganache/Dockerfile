FROM openresty/openresty:1.19.9.1-0-alpine-fat

RUN apk add --no-cache openssh-client

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;error_log /dev/stdout debug;"]
