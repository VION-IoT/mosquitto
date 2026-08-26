#!/bin/ash
set -e

# Only useful when the container is deliberately run as root (for example to fix up the
# ownership of a freshly created bind mount). The image's own default user is mosquitto.
if [ "$(id -u)" = '0' ]; then
	PUID="${PUID:-1883}"
	PGID="${PGID:-1883}"
	[ -d /mosquitto/data ] && chown -R "${PUID}:${PGID}" /mosquitto/data || true
	[ -d /mosquitto/log ]  && chown -R "${PUID}:${PGID}" /mosquitto/log  || true
fi

exec "$@"
