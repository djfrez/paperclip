#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

# Always ensure the instance directory tree exists and is fully owned by the
# app user. mkdir -p runs as root so we must chown from /paperclip downward to
# avoid any root-owned parent dirs blocking the app from creating subdirectories.
INSTANCE_ID=${PAPERCLIP_INSTANCE_ID:-default}
mkdir -p "/paperclip/instances/${INSTANCE_ID}"
chown -R node:node /paperclip

exec gosu node "$@"
