#!/bin/bash
set -e
DISK_NAME=$(lsblk -o NAME --noheadings --nodeps --paths | head --lines=1)
echo $DISK_NAME

# Se eliminan *todas* las particiones existentes en el primer disco listado.
sgdisk -Z $DISK_NAME
# Se definen nuevas particiones sobre el disco existente.
sgdisk -n 1:0:+1G $DISK_NAME
# Partición ESP (EFI System Partition) definida en un total de 1Gigabyte.
sgdisk -n 2:0:+40G $DISK_NAME
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
NVME="nvme"
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