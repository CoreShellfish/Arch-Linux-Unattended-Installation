#!/bin/bash
set -e
DISK_NAME=$(lsblk -o NAME,TYPE --noheadings --nodeps --paths | grep "disk" | head --lines=1 | awk '{print $1}')

# Sizes defined in Gigabytes, ex: BOOT_SIZE='1' > 1Gb
BOOT_SIZE='1'
ROOT_SIZE='60'

# Se eliminan *todas* las particiones existentes en el primer disco listado.
sgdisk -Z $DISK_NAME
# Se definen nuevas particiones sobre el disco existente.
sgdisk -n 1:0:+${BOOT_SIZE}G $DISK_NAME
# Partición ESP (EFI System Partition) definida en un total de 1Gigabyte.
sgdisk -n 2:0:+${ROOT_SIZE}G $DISK_NAME
# Ṕartición ROOT definida en un total de 40Gigabytes.
sgdisk -n 3:0:0 $DISK_NAME
# Partición HOME definida para el resto de espacio disponible a partir del último sector creado.

# Typecodes definidos para cada partición en pos de ser identificados correctamente
#por el kernel y la UEFI usando sus códigos hexadecimal correspondientes.
# Partición etiquetada como ESP.
sgdisk -t 1:ef00 $DISK_NAME
# Partición etiquetada como ROOT.
sgdisk -t 2:8304 $DISK_NAME
# Partición etiquetada como HOME
sgdisk -t 3:8302 $DISK_NAME

# Realizamos el formateo de cada partición para que adopte su sistema de archivos
# correspondiente.
if [[ $DISK_NAME == *[0-9] ]]; then
    PART_BOOT="${DISK_NAME}p1"
    PART_ROOT="${DISK_NAME}p2"
    PART_HOME="${DISK_NAME}p3"
else
    PART_BOOT="${DISK_NAME}1"
    PART_ROOT="${DISK_NAME}2"
    PART_HOME="${DISK_NAME}3"
fi
mkfs.fat -F 32 $PART_BOOT
mkfs.ext4 -F $PART_ROOT
mkfs.ext4 -F $PART_HOME
# Montado jerárquico
mount $PART_ROOT /mnt
mount --mkdir $PART_BOOT /mnt/boot/efi
mount --mkdir $PART_HOME /mnt/home

# Setup of the system main packages and utilities through the pacstrap script.
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager nano vim git sudo

# Transfer of the mounted partition structure to the filesystem table so
# the system know on each boot how partitions are defined.
genfstab -U /mnt >> /mnt/etc/fstab

# Pulling the arch-chroot setup script from the Arch-Linux-Unattended-Installation
# repository from Github.
curl -o /mnt/root/install_chroot.sh "https://raw.githubusercontent.com/CoreShellfish/Arch-Linux-Unattended-Installation/main/install_chroot.sh"

# Give admin privilegies in order to be able to execute the downloaded script.
chmod +x /mnt/root/install_chroot.sh

arch-chroot /mnt /root/install_chroot.sh

# Automatic unmounting of the /mnt directory before manual reboot
umount -R /mnt
echo 'Installation of the Arch Linux OS finished, type (reboot) to restart the system and remove the bootable device'
