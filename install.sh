#!/usr/bin/env bash
[[ -f /etc/arch-release ]] || {
  echo "Not Arch. Aborting."
  exit 1
}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

echo "==> Installing yay (AUR helper) if missing"
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

echo "==> Enabling multilib repository"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  sudo sed -i "/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//" /etc/pacman.conf
  sudo pacman -Sy
fi

echo "==> Installing pacman packages"
sudo pacman -S --needed --noconfirm - <"$REPO_DIR/packages/pacman.txt"

echo "==> Installing AUR packages"
yay -S --needed --noconfirm - <"$REPO_DIR/packages/aur.txt"

echo "==> Enabling system services"
sudo systemctl enable --now \
  NetworkManager.service \
  bluetooth.service \
  cups.socket \
  docker.service \
  libvirtd.service

echo "==> Adding $USER to docker and libvirt groups"
sudo usermod -aG docker,libvirt "$USER"

echo "==> Applying dotfiles via chezmoi"
chezmoi init --apply --source="$REPO_DIR"

echo "==> Applying papirus folder color"
papirus-folders -C palebrown --theme Papirus-Light

echo "==> Installing konsave via pipx"
if ! pipx list --short 2>/dev/null | grep -q '^konsave '; then
  pipx install konsave
fi
export PATH="$HOME/.local/bin:$PATH"

echo "==> Importing Konsave profile"
konsave -i "$REPO_DIR/konsave/rose-pine-dawn.knsv"
konsave -a rose-pine-dawn

echo "==> Rebuilding icon caches"
kbuildsycoca6 --noincremental || true

echo "==> Done. Log out and back in to apply Plasma settings and group changes."
