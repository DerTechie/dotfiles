#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

echo "==> Installing yay (AUR helper) if missing"
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

echo "==> Installing pacman packages"
sudo pacman -S --needed --noconfirm - < "$REPO_DIR/packages/pacman.txt"

echo "==> Installing AUR packages"
yay -S --needed --noconfirm - < "$REPO_DIR/packages/aur.txt"

echo "==> Applying dotfiles via chezmoi"
chezmoi init --source "$REPO_DIR"
chezmoi apply

echo "==> Applying papirus folder color"
papirus-folders -C palebrown --theme Papirus-Light

echo "==> Importing Konsave profile"
konsave -i "$REPO_DIR/konsave/rose-pine-dawn.knsv"
konsave -a rose-pine-dawn

echo "==> Rebuilding icon caches"
kbuildsycoca6 --noincremental || true

echo "==> Done. Log out and back in to apply Plasma settings fully."
