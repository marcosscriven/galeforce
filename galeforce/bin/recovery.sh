#! /bin/bash

ROOT="$(dirname "$0")/../.."
TEMP_MOUNT="/tmp/galeforce/installmnt"
NEW_USR_LOCAL="$TEMP_MOUNT/dev_image"

function makeNewUsrLocal() {
    mkdir -p "$TEMP_MOUNT"
    mount /dev/mmcblk0p1 "$TEMP_MOUNT"
    # Upon restart this gets mapped to /usr/local
    mkdir -p "$NEW_USR_LOCAL"
}

function copyGaleforce() {
    cp -R "$ROOT/galeforce" "$NEW_USR_LOCAL"

    # Permissions are probably ok, but lets make sure
    chmod u+x "$NEW_USR_LOCAL/galeforce/bin/*"
    chmod 700 "$NEW_USR_LOCAL/galeforce/bin/dropbear"
}

function linkBinaries() {
    ln -s "$NEW_USR_LOCAL/galeforce/bin/dropbear" "/usr/local/bin"

    # TODO Link busybox dynamically
    ln -s "$NEW_USR_LOCAL/galeforce/bin/busybox" "/usr/local/bin/wget"
    ln -s "$NEW_USR_LOCAL/galeforce/bin/busybox" "/usr/local/bin/vi"
}

makeNewUsrLocal
copyGaleforce
linkBinaries
