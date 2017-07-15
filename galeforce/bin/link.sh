#! /bin/bash

GALEFORCE_HOME="/usr/local/galeforce"

function link() {
    target=$1

    echo "Linking GaleForce to $target"
    pushd "$target"

    # Config
    ln -s "$GALEFORCE_HOME/conf/dropbear.conf" "etc/init/dropbear.conf"
    ln -s "$GALEFORCE_HOME/conf/galeforce.conf" "etc/init/galeforce.conf"

    # Data
    mkdir -p "$GALEFORCE_HOME/data/dropbear"
    ln -s "$GALEFORCE_HOME/data/dropbear" "etc/dropbear"

    # Shadow file to ensure root password (TODO - be smarter here)
    rm -rf "etc/shadow"
    ln -s "$GALEFORCE_HOME/conf/shadow" "etc/shadow"

    popd
}

echo "May the GaleForce be with you..."
target=$1
link "$target"
