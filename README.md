# GaleForce

[![Build Status](https://travis-ci.org/marcosscriven/galeforce.svg?branch=master)](https://travis-ci.org/marcosscriven/galeforce)

GaleForce is a project to customise the Google Wifi router, including enabling ssh access.

## Pre-built images

GaleForce uses Travis and produces tagged binaries available from [here](https://github.com/marcosscriven/galeforce/releases).

## How to build an image

Firstly - you **must ensure** you've checked out a tagged version of the code. Not every commit has been tested on the router.
If you're on a reasonably modern Linux system, you can simply run:

```
./bin/build-all.sh
```

If however you're on Windows or macOS, you'll need to use Vagrant (unfortunately
Docker for these systems don't have the necessary functions in their xhyve kernels to map loop devices properly):

```
vagrant up
vagrant ssh -c 'cd /vagrant; ./bin/build-all.sh'
```

Once completed (by either method), you can copy this image to a USB stick:

```
sudo dd if=output/gale.bin of=/dev/<usbdevice> bs=1m
```

## How to apply an image

You'll have to put the Google Wifi into developer mode:

![Alt text](http://i.imgur.com/iCPe0WO.jpg "Google WIfi")

1. Unscrew the single screw on the bottom
2. Insert a very slim blade or screwdriver to ease out the base cover
3. Insert a USB-C adapter with [Power Delivery](https://www.amazon.co.uk/gp/product/B01NBP36YY/ref=as_li_tl?ie=UTF8&camp=1634&creative=6738&creativeASIN=B01NBP36YY&linkCode=as2&tag=marcosscriven-21&linkId=35cc735debc0c8d627fa7fd21f8fc719)
4. Press the reset button on the back until light blinks orange ([exactly 16 seconds](https://chromium.googlesource.com/chromiumos/third_party/coreboot/+/firmware-gale-8281.B/src/mainboard/google/gale/chromeos.c#118))
5. Once blinking orange, hit the tiny [bubble switch](https://chromium.googlesource.com/chromiumos/third_party/coreboot/+/firmware-gale-8281.B/src/mainboard/google/gale/chromeos.c#78) (SW7 on the board - see image)
6. Device will start blinking purple and restart
7. Wait until device restarts and starts blinking purple again
8. Plug in USB stick
9. Hit bubble switch again
10. Wait about five minutes until device pulsing purple (device shows no lights while updating from USB)

Once installed you can then:

```
ssh root@192.168.86.1 (password changeme)
```

```
localhost ~ # uname -a
Linux localhost 3.18.0-14565-g46be31c1033f #1 SMP PREEMPT Fri Jun 2 14:42:21 PDT 2017 armv7l ARMv7 Processor rev 5 (v7l) Qualcomm (Flattened Device Tree) GNU/Linux

localhost ~ # cat /etc/lsb-release
CHROMEOS_AUSERVER=https://tools.google.com/service/update2
CHROMEOS_BOARD_APPID={9BC3D9F3-D113-8EA2-42D6-F2CDB8189814}
CHROMEOS_CANARY_APPID={90F229CE-83E2-4FAF-8479-E368A34938B1}
CHROMEOS_DEVSERVER=
CHROMEOS_RELEASE_APPID={9BC3D9F3-D113-8EA2-42D6-F2CDB8189814}
CHROMEOS_RELEASE_BOARD=gale-signed-mpkeys
CHROMEOS_RELEASE_BRANCH_NUMBER=40
CHROMEOS_RELEASE_BUILDER_PATH=gale-release/R59-9460.40.5
CHROMEOS_RELEASE_BUILD_NUMBER=9460
CHROMEOS_RELEASE_BUILD_TYPE=Official Build
CHROMEOS_RELEASE_CHROME_MILESTONE=59
CHROMEOS_RELEASE_DESCRIPTION=9460.40.5 (Official Build) stable-channel gale
CHROMEOS_RELEASE_NAME=Chrome OS
CHROMEOS_RELEASE_PATCH_NUMBER=5
CHROMEOS_RELEASE_TRACK=stable-channel
CHROMEOS_RELEASE_VERSION=9460.40.5
DEVICETYPE=OTHER
GOOGLE_RELEASE=9460.40.5
HWID_OVERRIDE=GALE DOGFOOD
```

## Busybox

I've also put busybox on there, and all extra commands it provides are on the path:

```
localhost ~ # ls -altr /usr/local/bin/wc
lrwxrwxrwx 1 root root /usr/local/bin/wc -> /usr/local/galeforce/bin/busybox
localhost ~ # wc --help
BusyBox v1.26.2 (2017-01-11 08:43:16 UTC) multi-call binary.
```

## Shell

The default shell seems to be dash, but you can change it easily enough. I prefer bash as it has tab completion and 
history navigation:

```
root@localhost $ chsh
Changing the login shell for root
Enter the new value, or press ENTER for the default
	Login Shell [/bin/dash]: /bin/bash
```

## Change the password (really)

```
localhost ~ # passwd
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
```

## Why not just build Chromium OS from source

I tried - it's fairly easy to do and [well documented](http://www.chromium.org/chromium-os/developer-guide#TOC-Select-a-board). 
However, with the Google Wifi (codename ```gale```), you'll find the [board overlays](http://www.chromium.org/chromium-os/developer-guide#TOC-Select-a-board) are not there. 
This means much of the config and blobs are [closed source](https://www.chromium.org/chromium-os/how-tos-and-troubleshooting/chromiumos-board-porting-guide/private-boards) and proprietary.

## Thanks

Thanks to these kind folk who helped me out on the [Chromium OS dev](https://groups.google.com/a/chromium.org/forum/?hl=en#!forum/chromium-os-dev) Google Group:

* Mike Frysinger	
* Bill Richardson	
* Bernie Thompson	
* Julius Werner

[Patching images](https://groups.google.com/a/chromium.org/forum/?hl=en#!topic/chromium-os-dev/nggdayKYTTE)

[Auto updates](https://groups.google.com/a/chromium.org/forum/?hl=en#!topic/chromium-os-dev/uLbB6t0BQPQ)
