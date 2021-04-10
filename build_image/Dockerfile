FROM alpine:3.13

ARG VERSION=3.3.5
ENV OBFS_DOWNLOAD_URL https://github.com/shadowsocks/simple-obfs.git

RUN set -ex && \
    apk add --no-cache \
        --virtual .build-deps \
        autoconf \
        build-base \
        curl \
        libev-dev \
        libcap \
        libtool \
        linux-headers \
        libsodium-dev \
        mbedtls-dev \
        pcre-dev \
        tar \
        net-tools\
        c-ares-dev && \
    mkdir -p /tmp/ss && \
    cd /tmp/ss && \
    curl -sSL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$VERSION/shadowsocks-libev-$VERSION.tar.gz | \
    tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make -j $((`nproc`+1)) install && \
    ls /usr/bin/ss-* | xargs -n1 setcap 'cap_net_bind_service+ep' && \
    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    cd / && rm -rf /tmp/* && \
    apk upgrade --update \
    && apk add --no-cache --virtual .build-deps \
        asciidoc \
        autoconf \
        automake \
        g++ \
        gcc \
        libev-dev \
        libpcre32 \
        libtool \
        linux-headers \
        make \
        openssl \
        xmlto \
        zlib-dev \
        git \
    && git clone ${OBFS_DOWNLOAD_URL} \
    && cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && cd .. \
    && rm -rf simple-obfs
