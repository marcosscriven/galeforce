#! /bin/bash

pushd $(dirname "$0")
source ./common.sh

BUSYBOX_URL="https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-armv6l"
DROPBEAR_URL="http://archive.raspbian.org/raspbian/pool/main/d/dropbear/dropbear-bin_2017.75-1_armhf.deb"

function downloadBusybox() {
  if [ ! -f "$DOWNLOADS_DIR/busybox" ]
  then
    echo "Downloading busybox"
    curl -s $BUSYBOX_URL -o $DOWNLOADS_DIR/busybox
  fi
}

function downloadDropbear() {
  if [ ! -f "$DOWNLOADS_DIR/dropbear" ]
  then
    echo "Downloading dropbear"
    curl -s $DROPBEAR_URL -o $DOWNLOADS_DIR/dropbear.deb
    pushd $DOWNLOADS_DIR/
    ar -x dropbear.deb
    tar -xf data.tar.xz
    cp usr/sbin/dropbear .
    popd
  fi
}

echo "Building GaleForce."
rm -rf $BUILD_DIR/galeforce
downloadDropbear
downloadBusybox
cp -R "../galeforce" $BUILD_DIR/galeforce
cp $DOWNLOADS_DIR/dropbear $BUILD_DIR/galeforce/bin
cp $DOWNLOADS_DIR/busybox $BUILD_DIR/galeforce/bin

popd