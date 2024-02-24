#!/bin/bash
# GPT-BIOS on RAID10 with BTRFS Install Script
# Your setup may differ -- modify accordingly
# Exit if any command fails
set -e


# Partition the disks
for disk in a b c d; do
    parted /dev/sd${disk} --script mklabel gpt
    parted /dev/sd${disk} --script mkpart primary 1MiB 1GiB
    parted /dev/sd${disk} --script mkpart primary 1GiB 100%
done

# Setup RAID 10
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sd[abcd]2

# Create Btrfs filesystem on RAID
mkfs.btrfs /dev/md0

# Create Btrfs subvolumes
mount /dev/md0 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@boot
umount /mnt

# Mount subvolumes
mount -o subvol=@ /dev/md0 /mnt
mkdir /mnt/{home,boot}
mount -o subvol=@home /dev/md0 /mnt/home
mount -o subvol=@boot /dev/md0 /mnt/boot

# Install GRUB bootloader
# pacman -S grub dosfstools mtools dialog networkmanager 
# for disk in a b c d; do
#     grub-install --target=i386-pc /dev/sd${disk}
# done
# sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block mdadm_udev filesystems keyboard fsck)/' /etc/mkinitcpio.conf
# mkinitcpio -P
# grub-mkconfig -o /boot/grub/grub.cfg

