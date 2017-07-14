# Galeforce

Galeforce is a minimal patch to the standard Google Wifi image, enabling ssh access.

## How to build image

If you're on a reasonably modern Linux system, you can simply run:

```
./patch-image.sh gale
```

If however you're on Windows or Mac, you'll need to use Vagrant (unfortunately
Docker for these systems don't have the necessary functions in its xhyve kernel to map loop devices properly):

```
    vagrant up
    vagrant ssh
    cd /vagrant
    ./patch-image.sh gale
```

Once completed (by either method), you can copy this image to a USB stick:

```
    sudo dd if=output/gale.bin of=/dev/<usbdevice> bs=1m
```

## How to apply image

You'll have to put the Google Wifi into developer mode:

1. Unscrew the single screw on the bottom
2. Insert a very slim blade or screwdriver to ease out the base cover
3. Insert a USB-C adapter with [Power Delivery](https://www.amazon.co.uk/s/ref=nb_sb_noss?url=search-alias%3Dcomputers&field-keywords=usb+c+adapter+power+delivery&rh=n%3A340831031%2Ck%3Ausb+c+adapter+power+delivery)
4. Press reset button on the back until light blinks orange (16 seconds)
5. Once blinking orange, hit the tiny bubble switch (SW7 on the board)
6. Device will start blinking purple
7. Wait until device restarts and starts blinking purple
8. Plug in USB stick
9. Hit bubble switch again
10. Wait about five minutes until device pulsing purple

Once install you can then:

```
ssh root@192.168.86.1 (password changeme)
```