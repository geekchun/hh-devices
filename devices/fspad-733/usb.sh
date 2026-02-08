#!/bin/bash

cd /sys/kernel/config/usb_gadget
mkdir g1
cd g1
echo "0x0502" > idVendor
echo "0x3235" > idProduct
mkdir functions/rndis.rn0
mkdir configs/c1.1
ln -s functions/rndis.rn0 configs/c1.1/

echo musb-hdrc.2.auto > UDC

ifconfig usb0 192.168.137.1 up
