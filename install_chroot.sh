#!/bin/bash
set -e
# Timezone configuration
ln -sf /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime
hwclock --systohc

# Setting locales
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#es_AR.UTF-8 UTF-8/es_AR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Identifier for the local network
echo "arch-vm" >> /etc/hostname

# Pass the root credentials to the batch change password script.

echo "root:root" | chpasswd

pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
curl -o /root/system_setup.sh "https://raw.githubusercontent.com/CoreShellfish/Arch-Linux-Unattended-Installation/main/system_setup.sh"
chmod +x /root/system_setup.sh

systemctl enable NetworkManager