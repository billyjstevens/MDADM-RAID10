#!/bin/bash

# This is the device partitioning script.
# It is based on my personal hardware setup but can be modified for you own needs.
#
# What will this script do?
# Configure (4) HDD's into GPT/BIOS partitions
# Create 3 RAID-10 far2 arrays (/dev/md0, /dev/md1, /dev/md2)
# Run mkfs.ext4 on each RAID array
# Mount the root, boot, and home partitions
# Generate FSTAB

# Exit script on error
set -e

# Create GPT partitions
echo 'Creating GPTPartitions';
for drive in a b c d; do        # Selects /dev/sda /dev/sdb /dev/sdc /dev/sdd
  gdisk /dev/sd${drive} <<EOL   # and repeats the partitioning below on each

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

echo "Creating RAID-10 Arrays";
mdadm --create /dev/md1 --level=10 --layout=f2 --metadata=1.0 --raid-devices=4 /dev/sda3 /dev/sdb3 /dev/sdc3 /dev/sdd3
echo "The ROOT array, /dev/md1 complete."; break 2

mdadm --create /dev/md2 --level=10 --layout=f2 --metadata=1.0 --raid-devices=4 /dev/sda4 /dev/sdb4 /dev/sdc4 /dev/sdd4
echo "The HOME array, /dev/md2 complete."; break 2

mdadm --create /dev/md0 --level=10 --layout=f2 --metadata=1.0 --raid-devices=4 /dev/sda2 /dev/sdb2 /dev/sdc2 /dev/sdd2
echo "The BOOT array, /dev/md0 complete."; break 2

echo "Formatting the RAID arrays";
for array in 0 1 2; do
  mkfs.ext4 /dev/md${array}
done

echo "Mounting root..."; break 2
mount /dev/md1 /mnt
lsblk |grep md1
break 1;
echo "Creating boot, home, and etc directories."; break 2
mkdir -p /mnt/{boot,home,etc}
ls /mnt; break 1
echo "Mounting home..."; break 2
mount /dev/md2 /mnt/home
lsblk |grep md2
break 1;
echo "Mounting boot..."; break 2
mount /dev/md0 /mnt/boot
lsblk |grep md0
break 1;

echo "Generating: File System Table"; break 1
genfstab -U /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab; break 1

