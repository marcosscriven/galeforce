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
    chmod u+x "$NEW_USR_LOCAL/galeforce/bin/busybox"
    chmod 700 "$NEW_USR_LOCAL/galeforce/bin/dropbear"
}

function linkBinaries() {
    mkdir -p "$NEW_USR_LOCAL/bin"
    ln -s "/usr/local/galeforce/bin/dropbear" "$NEW_USR_LOCAL/bin"

    # TODO Link busybox dynamically
    ln -s "/usr/local/galeforce/bin/busybox" "$NEW_USR_LOCAL/bin/wget"
    ln -s "/usr/local/galeforce/bin/busybox" "$NEW_USR_LOCAL/bin/vi"
}

installRoot=$1

echo "Setting up GaleForce in: $NEW_USR_LOCAL and installing into: $installRoot"

makeNewUsrLocal
copyGaleforce
linkBinaries

# TODO This is quite brittle - need to dynamically find out what $installRoot is mapped to
mount -o remount,rw /dev/loop2 /tmp/install-mount-point

$ROOT/galeforce/bin/patch.sh $NEW_USR_LOCAL/galeforce $installRoot

# Handy for debug in the recovery.log on USB stick
echo "Contents of new usr/local:"
ls -altrR $NEW_USR_LOCAL