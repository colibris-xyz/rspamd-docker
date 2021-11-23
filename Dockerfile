FROM alpine:edge

RUN apk add --no-cache glib-dev icu-dev libsodium-dev luajit-dev openssl1.1-compat-dev pcre2-dev perl ragel sqlite-dev zlib-dev zstd-dev vectorscan-dev \
  && apk add --no-cache --virtual .build-deps curl build-base cmake pkgconfig

ARG RSPAMD_VERSION=3.0

RUN curl -L -o /tmp/rspamd.zip https://github.com/rspamd/rspamd/archive/refs/tags/${RSPAMD_VERSION}.zip \
  && unzip -d /tmp/rspamd /tmp/rspamd.zip \
  && mkdir /tmp/rspamd.build \
  && cd /tmp/rspamd.build \
  && cmake /tmp/rspamd/rspamd-3.0 -DENABLE_HYPERSCAN=ON -DENABLE_LUAJIT=ON -DCMAKE_BUILD_TYPE=RelWithDebuginfo \
  && make \
  && make install \
  && rm /tmp/rspamd.zip \
  && apk --purge del .build-deps

WORKDIR /usr/local/etc/rspamd

RUN mkdir /var/lib/rspamd \
  && chown nobody:nobody /var/lib/rspamd \
  && chown nobody:nobody /usr/local/etc/rspamd \
  && mkdir /usr/local/etc/rspamd/override.d \
  && echo 'type = "console";' > /usr/local/etc/rspamd/override.d/logging.inc \
  && echo 'bind_socket = "*:11334";' > /usr/local/etc/rspamd/override.d/worker-controller.inc \
  && echo 'pidfile = false;' > /usr/local/etc/rspamd/options.inc

USER nobody

CMD [ "/usr/local/bin/rspamd", "-f", "-c", "/usr/local/etc/rspamd/rspamd.conf" ]
