# vioniot/mosquitto

Minimal Mosquitto image built from this fork, so docker-based gateways run the **same broker
version** as the Windows gateway: Eclipse Mosquitto 2.1.2 with four upstream fixes backported
(`517ea607`, `4cf0eb29`, `8a67d1bb`, `24c72a61`).

Two of those are Windows-only code paths and have no effect here. The image exists for version
parity and a single source of truth, not because Linux needed the fix.

## Build

```
docker build -f docker/vion/Dockerfile \
    --build-arg SOURCE_COMMIT=$(git rev-parse HEAD) \
    -t vioniot/mosquitto:2.1.2-vion.1 .
```

Multi-arch, matching the other VION images:

```
docker buildx build -f docker/vion/Dockerfile \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --build-arg SOURCE_COMMIT=$(git rev-parse HEAD) \
    -t vioniot/mosquitto:2.1.2-vion.1 --push .
```

## What is in it

Broker, `mosquitto_passwd`, `mosquitto_pub`, `mosquitto_sub`, `mosquitto_signal`, and the
`acl-file`, `password-file` and `dynamic-security` plugins.

Built with TLS, TLS-PSK and bridge support. Built **without** websockets, the HTTP dashboard,
sqlite persistence, sparkplug-aware and the example plugins — that is what keeps the runtime
dependencies down to OpenSSL, cJSON and ca-certificates.

## Running

The broker runs as uid/gid 1883 (`mosquitto`), not root, and listens on 1883.

The bundled `/mosquitto/config/mosquitto.conf` allows anonymous access, matching the upstream
`eclipse-mosquitto` image's default so nothing is surprising. **It is for `docker run` smoke tests
only.** Real deployments mount their own config directory, which mesh provisions with an mTLS
listener plus `password_file` and `acl_file`:

```
docker run -d --name mosquitto \
    -v /srv/mosquitto/config:/mosquitto/config \
    -v /srv/mosquitto/data:/mosquitto/data \
    -p 1883:1883 vioniot/mosquitto:2.1.2-vion.1
```

Mounted files should be owned by uid 1883. Mosquitto currently warns when they are not, and
says future versions will refuse to load them.

## Reloading without a restart

Either works, and neither restarts the broker:

```
docker exec mosquitto mosquitto_signal -a config-reload
docker kill -s HUP mosquitto
```

Verified: a user absent from the password file went from `Not authorized` to publishing
successfully after swapping the auth files and signalling, with the same PID and zero restarts.
