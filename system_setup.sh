#!/bin/bash
set -e

# User provisioning.
read -p "Ingrese el nombre de usuario definitivo que desea crear: " NOMBRE_USUARIO
useradd -m -G wheel -s /bin/bash "$NOMBRE_USUARIO"
passwd "$NOMBRE_USUARIO"

# Enabling Multilib repository 
sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf

pacman -Syu --noconfirm

PKGS_SISTEMA="pipewire pipewire-pulse wireplumber networkmanager"
PKGS_GRAFICOS="mesa lib32-mesa"
PKGS_UI="hyprland waybar kitty wofi"
PKGS_UTILIDAD="firefox blender inkscape krita bitwarden vlc-plugins-all pavucontrol neovim yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick"
PKGS_OCIO="discord steam retroarch"

pacman -S --noconfirm $PKGS_SISTEMA $PKGS_GRAFICOS $PKGS_UI $PKGS_UTILIDAD $PKGS_OCIO

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.vinegarhq.Sober

systemctl enable NetworkManager.service
systemctl --global enable wireplumber.service

cd /tmp
sudo -u "$NOMBRE_USUARIO" git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u "$NOMBRE_USUARIO" makepkg -si --noconfirm
