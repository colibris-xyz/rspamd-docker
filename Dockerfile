FROM alpine:3.16.2

ARG TARGETPLATFORM

RUN apk add --no-cache glib-dev icu-dev libsodium-dev luajit-dev openssl1.1-compat-dev pcre2-dev perl ragel sqlite-dev zlib-dev zstd-dev \
  && if [ "$TARGETPLATFORM" = "linux/amd64" ]; then apk add --no-cache vectorscan-dev; fi

ARG RSPAMD_VERSION=3.3

RUN apk add --no-cache --virtual .build-deps curl build-base cmake pkgconfig \
  && curl -L -o /tmp/rspamd.zip https://github.com/rspamd/rspamd/archive/refs/tags/${RSPAMD_VERSION}.zip \
  && unzip -d /tmp/rspamd /tmp/rspamd.zip \
  && mkdir /tmp/rspamd.build \
  && cd /tmp/rspamd.build \
  && if [ "$TARGETPLATFORM" = "linux/amd64" ]; then enable_hyperscan="ON"; else enable_hyperscan="OFF"; fi \
  && cmake /tmp/rspamd/rspamd-${RSPAMD_VERSION} -DENABLE_HYPERSCAN=$enable_hyperscan -DENABLE_LUAJIT=ON -DCMAKE_BUILD_TYPE=RelWithDebuginfo \
  && make \
  && make install \
  && rm /tmp/rspamd.zip \
  && apk --purge del .build-deps

WORKDIR /usr/local/etc/rspamd

RUN mkdir /var/lib/rspamd \
  && chown nobody:nobody /var/lib/rspamd \
  && chown nobody:nobody /usr/local/etc/rspamd \
  && sed -i '\
     s/type = "file"/type = "console"/g; \
     s/bind_socket = "localhost:11332"/bind_socket = "*:11332"/g; \
     s/bind_socket = "localhost:11333"/bind_socket = "*:11333"/g; \
     s/bind_socket = "localhost:11334"/bind_socket = "*:11334"/g; \
     ' /usr/local/etc/rspamd/rspamd.conf \
  && echo 'pidfile = false;' >> /usr/local/etc/rspamd/options.inc

USER nobody

CMD [ "/usr/local/bin/rspamd", "-f", "-c", "/usr/local/etc/rspamd/rspamd.conf" ]
