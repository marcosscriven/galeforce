#! /bin/bash

ROOT_DIR="$(dirname "$0")/../../../.."
GALEFORCE_HOME="$ROOT_DIR/usr/local/galeforce"

echo "May the GaleForce be with you..."

ln -s "$GALEFORCE_HOME/conf/dropbear.conf" "$ROOT_DIR/etc/init/dropbear.conf"
ls -altr $ROOT_DIR/etc/init/dropbear.conf