#! /bin/bash

# See the following links on how read/write lock is removed:
# https://chromium.googlesource.com/chromiumos/platform/vboot_reference/+/master/scripts/image_signing/make_dev_ssd.sh#303
# https://chromium.googlesource.com/chromiumos/platform/vboot_reference/+/master/scripts/image_signing/common_minimal.sh#279
#
# See the following on how kernel verification is removed:
# https://chromium.googlesource.com/chromiumos/platform/vboot_reference/+/master/scripts/image_signing/make_dev_ssd.sh#63

IMAGE_METADATA_URL="https://dl.google.com/dl/edgedl/chromeos/recovery/onhub_recovery.json"
DEV_KEYS_URL="https://chromium.googlesource.com/chromiumos/platform/vboot_reference/+archive/master/tests/devkeys.tar.gz"
BUSYBOX_URL="https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-armv6l"
DROPBEAR_URL="http://archive.raspbian.org/raspbian/pool/main/d/dropbear/dropbear-bin_2017.75-1_armhf.deb"

BASE_DIR="/tmp/chromeos"
DOWNLOADS_DIR="$BASE_DIR/downloads"
DEV_KEYS_DIR="$BASE_DIR/devkeys"
BUILD_DIR="$BASE_DIR/build"
MOUNTS_DIR="$BUILD_DIR/mounts"
OUTPUT_DIR=output

rm -rf $BUILD_DIR
mkdir -p $DOWNLOADS_DIR
mkdir -p $DEV_KEYS_DIR
mkdir -p $BUILD_DIR
mkdir -p $OUTPUT_DIR

function getImageMetadata() {
  curl -s $IMAGE_METADATA_URL | jq '.[] | select(.hwidmatch | test(".*'"$BOARD"'.*";"i"))| {name, sha1, url}'
}

function unpackImage() {
  if [ -f "$DOWNLOADS_DIR/$BOARD.bin" ]
  then
    echo "Already unpackaged image for board: $BOARD"
    return
  fi

  echo "Unpacking: "$BOARD.bin.zip""
  unzip -p "$DOWNLOADS_DIR/$BOARD.bin.zip" > "$DOWNLOADS_DIR/$BOARD.bin"
}

function verifySha1() {
  sha1=$1

  echo "$sha1 *$DOWNLOADS_DIR/$BOARD.bin.zip" | shasum -c - > /dev/null
  return $?
}

function downloadDevKeys() {
  if [ ! -f "$DOWNLOADS_DIR/devkeys.tar.gz" ]
  then
    echo "Downloading dev keys"
    devKeysFile=$DOWNLOADS_DIR/devkeys.tar.gz
    curl -s $DEV_KEYS_URL -o $devKeysFile
    tar -xzf $devKeysFile  -C $DEV_KEYS_DIR kernel_data_key.vbprivk
    tar -xzf $devKeysFile  -C $DEV_KEYS_DIR kernel.keyblock
  fi
}

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

function downloadRecoveryImage() {
  if [ -f "$DOWNLOADS_DIR/$BOARD.bin.zip" ]
  then
    return
  fi

  echo "Finding latest image for board: $BOARD"
  imageMetadata=$(getImageMetadata)

  name=$(jq -r '.name' <<< $imageMetadata)
  url=$(jq -r '.url' <<< $imageMetadata)
  sha1=$(jq -r '.sha1' <<< $imageMetadata)

  echo "Found image for $name"
  echo "Downloading: $url"
  curl -s $url -o "$DOWNLOADS_DIR/$BOARD.bin.zip"

  if $(verifySha1 $sha1)
  then
    unpackImage
  else
    echo "SHA1 does not match $sha1"
    exit
  fi
}

function downloadDependencies() {
    downloadDevKeys
    downloadBusybox
    downloadDropbear
    downloadRecoveryImage
}

function getPartitionOffset() {
  partitionName=$1

  img=$BUILD_DIR/$BOARD.bin
  parted $img unit B print | grep $partitionName | tr -s ' ' | cut -d ' ' -f3 | sed 's/B//'
}

function getLoopDeviceForPartition() {
  partitionName=$1

  img=$BUILD_DIR/$BOARD.bin
  partitionNumber=$(parted $img unit B print | grep $partitionName | tr -s ' ' | cut -d ' ' -f2)
  echo "/dev/mapper/loop0p$partitionNumber"
}

function enableReadWrite() {
  partitionName=$1

  img=$BUILD_DIR/$BOARD.bin
  offset=$(getPartitionOffset $partitionName)

  # See head of file on how this magic offset was established
  magicOffset=$((offset + 1127))
  echo "Removing rw lock at magic offset: $magicOffset"
  printf '\000' | sudo dd of=$img seek=$magicOffset conv=notrunc count=1 bs=1 > /dev/null 2>&1
}

function remove_verification() {
    newConfig=$1
    newConfig=$(sed 's/ ro / rw /' <<< $newConfig)
    newConfig=$(sed 's/ root=\/dev\/dm-[0-9] / root=PARTUUID=%U\/PARTNROFF=1 /' <<< $newConfig)
    newConfig=$(sed 's/ dm_verity.dev_wait=1 / dm_verity.dev_wait=0 /' <<< $newConfig)
    newConfig=$(sed 's/ payload=PARTUUID=%U\/PARTNROFF=1 / payload=ROOT_DEV /' <<< $newConfig)
    newConfig=$(sed 's/ hashtree=PARTUUID=%U\/PARTNROFF=1 / hashtree=HASH_DEV /' <<< $newConfig)
    echo "$newConfig"
}

function patchRoot() {
  rootName=$1

  enableReadWrite $rootName
  mountPartition $rootName
  mountPoint="$MOUNTS_DIR/$rootName"

  # This is just so we get something in the recovery.log file to grep
  sudo sh -c "echo 'echo \"All your base are belong to us\"' >> $mountPoint/usr/sbin/chromeos-postinst"

  # Copy galeforce over and prepare empty dirs
  galeforceRoot=$mountPoint/galeforce/root
  sudo cp -R galeforce $mountPoint
  sudo mkdir -p $galeforceRoot/bin

  # Add busybox binary
  sudo cp $DOWNLOADS_DIR/busybox $galeforceRoot/bin
  sudo chmod ugo+rx $galeforceRoot/bin/busybox

  # Add dropbear binary
  sudo cp $DOWNLOADS_DIR/dropbear $galeforceRoot/bin
  sudo chmod 700 $galeforceRoot/bin/dropbear

  # Run patch
  sudo $mountPoint/galeforce/patch.sh

  unmountPartition $rootName
}

function patchKernel() {
  partitionName=$1

  img=$BUILD_DIR/$BOARD.bin
  loopDevice=$(getLoopDeviceForPartition $partitionName)

  echo "Extracting kernal partition $partitionName"
  kernelFile="$BUILD_DIR/kernel"
  sudo dd if=$loopDevice of=$kernelFile > /dev/null 2>&1

  kernelConfig=$(sudo vbutil_kernel --verify $kernelFile --verbose | tail -1)
  echo "Current config: $kernelConfig"

  patchedKernelConfig=$(remove_verification "$kernelConfig")
  echo "Patched config: $patchedKernelConfig"
  patchedKernelConfigFile=$BUILD_DIR/kernel.config
  echo $patchedKernelConfig > $patchedKernelConfigFile

  repackedKernelFile=$BUILD_DIR/repacked
  vbutil_kernel \
    --repack $repackedKernelFile \
    --signprivate $DEV_KEYS_DIR/kernel_data_key.vbprivk \
    --keyblock $DEV_KEYS_DIR/kernel.keyblock \
    --oldblob $kernelFile \
    --config $patchedKernelConfigFile

  vbutil_kernel --verify $repackedKernelFile --verbose

  sudo dd if=$repackedKernelFile of=$loopDevice > /dev/null 2>&1

  # Cleanup
  sudo rm $kernelFile $repackedKernelFile $patchedKernelConfigFile
}


function mountPartition() {
  partitionName=$1

  mountDir="$MOUNTS_DIR/$partitionName"
  mkdir -p $mountDir

  echo "Mounting $partitionName to $mountDir"
  sudo mount $(getLoopDeviceForPartition $partitionName) $mountDir
}

function unmountPartition() {
  partitionName=$1

  mountDir="$MOUNTS_DIR/$partitionName"
  echo "Unmounting $partitionName from $mountDir"
  sudo umount $mountDir
}

function createPatchImage() {
  echo "Copying image to $BUILD_DIR dir"
  cp "$DOWNLOADS_DIR/$BOARD.bin" $BUILD_DIR/$BOARD.bin

  echo "Mapping partitions to loop devices"
  sudo kpartx -a $BUILD_DIR/$BOARD.bin

  # This is the main root (there's also ROOT-B)
  patchRoot ROOT-A

  # This is the recovery kernel
  patchKernel KERN-A

  # This is the kernel that gets written to disk
  patchKernel KERN-B

  echo "Unmapping loop devices"
  sudo kpartx -d $BUILD_DIR/$BOARD.bin

  # Finally compress and copy to output
  pushd
  cp $BUILD_DIR/$BOARD.bin.tar.gz $OUTPUT_DIR
  popd
  echo "Patched image has been copied to $OUTPUT_DIR/$BOARD.bin.tar.gz"
}

if ! $(echo $1 | grep -q -w -E "arkham|gale|whirlwind")
then
  echo "You must specify a board name. E.g. arkham|gale|whirlwind"
  exit
fi

BOARD=$1

downloadDependencies
createPatchImage
