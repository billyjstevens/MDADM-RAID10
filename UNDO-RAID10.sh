#!/bin/bash
# RAID device to dismantle
RAID_DEVICE="/dev/md0 /dev/md1 /dev/md2"
# Drives that were part of the RAID array
DRIVES="/dev/sda /dev/sdb /dev/sdc /dev/sdd"
# Unmount the RAID array if mounted
umount ${RAID_DEVICE}* || echo "No mounts found for ${RAID_DEVICE}"
# Stop the RAID array
mdadm --stop ${RAID_DEVICE}
# Remove RAID superblock from each drive
for drive in ${DRIVES}; do
mdadm --zero-superblock ${drive}
done
echo "RAID10 array ${RAID_DEVICE} has been dismantled. Drives are now separate."
