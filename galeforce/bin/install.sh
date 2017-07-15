#! /bin/bash

GALEFORCE_ROOT="$(dirname "$0")/.."

function install() {
    target=$1

    echo "Installing GaleForce to $target"

    # Config - sadly we have to actually copy these over - symlinks are ignored.
    cp "$GALEFORCE_ROOT/conf/dropbear.conf" "$target/etc/init/dropbear.conf"
    cp "$GALEFORCE_ROOT/conf/galeforce.conf" "$target/etc/init/galeforce.conf"
    cp "$GALEFORCE_ROOT/conf/dropbear.conf" "$target/etc/init/telnet.conf"

    # Data
    ln -s "/usr/local/galeforce/data/dropbear" "$target/etc"

    # Replace shadow file to ensure root password (TODO - be smarter here)
    rm -rf "$target/etc/shadow"
    cp "$GALEFORCE_ROOT/conf/shadow" "$target/etc/shadow"
}

echo "May the GaleForce be with you..."
target=$1
install "$target"
echo "Finished installing"
