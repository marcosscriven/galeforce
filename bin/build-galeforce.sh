#! /bin/bash

pushd $(dirname "$0")
source ./common.sh

BUSYBOX_URL="https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-armv6l"
DROPBEAR_URL="http://archive.raspbian.org/raspbian/pool/main/d/dropbear/dropbear-bin_2016.74-5%2Bdeb9u1_armhf.debc"
DROPBEAR_BASE_URL="http://archive.raspbian.org/raspbian/pool/main/dropbear"

function downloadBusybox() {
  if [ ! -f "$DOWNLOADS_DIR/busybox" ]
  then
    echo "Downloading busybox"
    curl -s $BUSYBOX_URL -o $DOWNLOADS_DIR/busybox
  fi
}

# go get github.com/ericchiang/pup
function getDropbearURL() {
  filename=$(curl -s $DROPBEAR_BASE_URL | pup 'a attr{href}' | grep dropbear-bin | grep 2016)
  echo $DROPBEAR_BASE_URL/$filename
}

function downloadDropbear() {
  if [ ! -f "$DOWNLOADS_DIR/dropbear" ]
  then
    echo "Downloading dropbear"
    mkdir -p $DOWNLOADS_DIR/extract
    pushd $DOWNLOADS_DIR/extract
    curl -sf $DROPBEAR_URL -o dropbear.deb
    if [ $? -ne 0 ]; then
      echo Failed to download dropbear - please check DROPBEAR_URL variable in $0
      exit 1
    else
      echo "Downloaded successfully"
    fi
    ar -x dropbear.deb
    tar -xf data.tar.xz
    cp usr/sbin/dropbear ../
    popd
    rm -rf $DOWNLOADS_DIR/extract
  fi
}

echo "Building GaleForce."

rm -rf $BUILD_DIR/galeforce
downloadDropbear
downloadBusybox
cp -R "../galeforce" $BUILD_DIR/galeforce
cp $DOWNLOADS_DIR/dropbear $BUILD_DIR/galeforce/bin
chmod 700 $BUILD_DIR/galeforce/bin/dropbear

cp $DOWNLOADS_DIR/busybox $BUILD_DIR/galeforce/bin
chmod u+x $BUILD_DIR/galeforce/bin/busybox

pushd $BUILD_DIR
tar -czf galeforce.tar.gz galeforce
popd

cp $BUILD_DIR/galeforce.tar.gz $OUTPUT_DIR

popd