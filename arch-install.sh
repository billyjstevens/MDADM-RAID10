#!/bin/bash
# GPT-BIOS on RAID10 with BTRFS Install Script
# Your setup may differ -- modify accordingly
# Exit if any command fails
set -e

# Step 1: Update the system clock
timedatectl set-ntp true

# Step 2: Partition the disks
for disk in a b c d; do
    parted /dev/sd${disk} --script mklabel gpt
    parted /dev/sd${disk} --script mkpart primary 1MiB 1GiB
    parted /dev/sd${disk} --script mkpart primary 1GiB 100%
done

# Step 3: Setup RAID 10
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sd[abcd]2

# Step 4: Create Btrfs filesystem on RAID
mkfs.btrfs /dev/md0

# Step 5: Create Btrfs subvolumes
mount /dev/md0 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@boot
umount /mnt

# Step 6: Mount subvolumes
mount -o subvol=@ /dev/md0 /mnt
mkdir /mnt/{home,boot}
mount -o subvol=@home /dev/md0 /mnt/home
mount -o subvol=@boot /dev/md0 /mnt/boot

# Step 7: Install base system
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 50/' /etc/pacman.conf
pacstrap /mnt base linux-lts linux-rt-lts linux-lts-headers linux-rt-lts-headers linux-firmware mdadm btrfs-progs neovim

# Step 8: Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Step 9: Chroot into new system
arch-chroot /mnt /bin/bash <<EOF

# Step 10: Configure system
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "archlinux" > /etc/hostname
echo "127.0.1.1 archlinux.localdomain archlinux" >> /etc/hosts

# Step 11: Set root password
echo "root:password" | chpasswd

# Step 12: Install and configure bootloader
pacman -S grub dosfstools mtools dialog networkmanager 
for disk in a b c d; do
    grub-install --target=i386-pc /dev/sd${disk}
done
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block mdadm_udev filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Step 13: Unmount and reboot
umount -R /mnt
reboot
