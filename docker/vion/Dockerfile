# Minimal Mosquitto image for VION gateways, built from this fork so that docker-based gateways
# and the Windows gateway run the identical broker version.
#
# Two stages: nothing from the toolchain reaches the runtime image. The build is deliberately
# trimmed to what a VION gateway broker actually uses - TLS, bridges, and the auth-file and
# dynamic-security plugins. Websockets, the HTTP dashboard, sqlite persistence, sparkplug and the
# example plugins are all off, which is what keeps the image small and its runtime dependencies
# down to OpenSSL and cJSON.
ARG ALPINE_VERSION=3.23

FROM alpine:${ALPINE_VERSION} AS build

RUN apk add --no-cache \
        build-base \
        cjson-dev \
        cmake \
        linux-headers \
        ninja \
        openssl-dev

WORKDIR /src
COPY . /src

RUN cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DWITH_TLS=ON \
        -DWITH_TLS_PSK=ON \
        -DWITH_BRIDGE=ON \
        -DWITH_DOCS=OFF \
        -DWITH_TESTS=OFF \
        -DWITH_WEBSOCKETS=OFF \
        -DWITH_CTRL_SHELL=OFF \
        -DWITH_PLUGIN_EXAMPLES=OFF \
        -DWITH_PLUGIN_PERSIST_SQLITE=OFF \
        -DWITH_PLUGIN_SPARKPLUG_AWARE=OFF \
    && cmake --build build --parallel "$(nproc)" \
    && DESTDIR=/stage cmake --install build --strip

# Reduce the staged install to exactly what the runtime ships, so the final stage copies one tree
# instead of enumerating paths that differ by platform - libmosquitto_common, for instance, is a
# shared library on Windows and static here.
RUN cd /stage/usr \
    && rm -rf include lib/pkgconfig etc \
    && rm -f lib/libmosquittopp.so* bin/mosquitto_ctrl bin/mosquitto_db_dump bin/mosquitto_rr \
    && install -Dm644 /src/epl-v20 /stage/usr/share/licenses/mosquitto/epl-v20 \
    && install -Dm644 /src/edl-v10 /stage/usr/share/licenses/mosquitto/edl-v10 \
    && find /stage -type f -o -type l | sort | sed 's|/stage||'


FROM alpine:${ALPINE_VERSION}

ARG VERSION=2.1.2-vion.1
ARG SOURCE_COMMIT=unknown

LABEL \
    org.opencontainers.image.title="vioniot/mosquitto" \
    org.opencontainers.image.description="Eclipse Mosquitto 2.1.2 with four upstream Windows signal fixes backported (517ea607, 4cf0eb29, 8a67d1bb, 24c72a61). Same broker version as the VION Windows gateway." \
    org.opencontainers.image.vendor="VION IoT" \
    org.opencontainers.image.source="https://github.com/VION-IoT/mosquitto" \
    org.opencontainers.image.url="https://github.com/VION-IoT/mosquitto/releases/tag/v2.1.2-vion.1" \
    org.opencontainers.image.documentation="https://mosquitto.org/documentation/" \
    org.opencontainers.image.licenses="EPL-2.0 OR BSD-3-Clause" \
    org.opencontainers.image.base.name="docker.io/library/alpine" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.revision="${SOURCE_COMMIT}"

RUN apk add --no-cache \
        ca-certificates \
        cjson \
        libcrypto3 \
        libssl3 \
    && addgroup -S -g 1883 mosquitto \
    && adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto \
    && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log

COPY --from=build /stage/usr/ /usr/
COPY docker/vion/mosquitto.conf       /mosquitto/config/mosquitto.conf
COPY docker/vion/docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh && chown -R mosquitto:mosquitto /mosquitto

VOLUME ["/mosquitto/data", "/mosquitto/log"]
EXPOSE 1883

USER mosquitto
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
