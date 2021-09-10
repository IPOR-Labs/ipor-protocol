FROM openresty/openresty:1.19.9.1-0-alpine-fat

RUN apk add --no-cache openssh-client git

RUN mkdir -p /etc/sockproc
WORKDIR /etc
RUN git clone https://github.com/juce/sockproc.git

WORKDIR /etc/sockproc
RUN make

COPY content/entrypoint.sh /entrypoint.sh

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
