#! /bin/bash

GALEFORCE_ROOT="$(dirname "$0")/.."

function install() {
    target=$1

    echo "Installing GaleForce to $target"

    # Config
    cp "$GALEFORCE_ROOT/conf/dropbear.conf" "$target/etc/init/dropbear.conf"
    cp "$GALEFORCE_ROOT/conf/galeforce.conf" "$target/etc/init/galeforce.conf"
    cp "$GALEFORCE_ROOT/conf/dropbear.conf" "$target/etc/init/telnet.conf"

    # Data
    mkdir -p "$target/etc/dropbear"
    cp "$GALEFORCE_ROOT/data/dropbear" "$target/etc/dropbear"

    # Shadow file to ensure root password (TODO - be smarter here)
    rm -rf "$target/etc/shadow"
    cp "$GALEFORCE_ROOT/conf/shadow" "$target/etc/shadow"
}

echo "May the GaleForce be with you..."
target=$1
install "$target"
echo "Finished installing"
