#!/bin/bash
# Create GPT partitions on each drive
for drive in a b c d; do
  gdisk /dev/sd${drive} <<EOL
o
y
x
L
1
m
n
1
40
2047
ef02
x
L
2048
m
n
2

+1G
fd00
n
3

+128G
fd00
n
4


fd00
w
y
EOL
done
# Create the RAID arrays
mdadm --create /dev/md0 --level=10 --layout=f2 --metadata=1.0 --raid-devices=4 /dev/sda2 /dev/sdb2 /dev/sdc2 /dev/sdd2
mdadm --create /dev/md1 --level=10 --layout=f2 --metadata=1.0 --raid-devices=4 /dev/sda3 /dev/sdb3 /dev/sdc3 /dev/sdd3
mdadm --create /dev/md2 --level=10 --layout=f2 --metadata=1.0 --raid-devices=4 /dev/sda4 /dev/sdb4 /dev/sdc4 /dev/sdd4
# Format the RAID arrays
mkfs.ext4 /dev/md0
mkfs.ext4 /dev/md1
mkfs.ext4 /dev/md2
# Mount the RAID arrays
# MD1 is / or root
# MD0 is /boot
# md2 is /home

