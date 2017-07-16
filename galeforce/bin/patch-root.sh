#! /bin/bash

GALEFORCE_DIR=$1
NEW_ROOT=$2

function patch() {
    echo "Patching new root $NEW_ROOT from $GALEFORCE_DIR"

    # Symlinks must be absolute as we may be installing from different locations
    ln -s "/usr/local/galeforce/data/dropbear" "$NEW_ROOT/etc"

    # Replace shadow file to ensure root password (TODO - be smarter here)
    rm -rf "$NEW_ROOT/etc/shadow"
    cp "$GALEFORCE_DIR/conf/shadow" "$NEW_ROOT/etc/shadow"

    # Config - sadly we have to actually copy these over - symlinks are ignored.
    cp "$GALEFORCE_DIR/conf/dropbear.conf" "$NEW_ROOT/etc/init/dropbear.conf"
    cp "$GALEFORCE_DIR/conf/galeforce.conf" "$NEW_ROOT/etc/init/galeforce.conf"

    echo "Finished patching."
}

echo "May the GaleForce be with you..."
patch