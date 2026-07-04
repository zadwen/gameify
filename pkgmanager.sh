#!/usr/bin/env bash
# lib/pkgmanager.sh — thin abstraction so the rest of the code doesn't care
# whether it's running on apt, dnf, pacman, or zypper.
set -euo pipefail

# PKG_FAMILY must be set (debian|fedora|arch|opensuse|unknown) before sourcing use.

pkg_update() {
  case "$PKG_FAMILY" in
    debian) sudo apt update ;;
    fedora) sudo dnf -y makecache ;;
    arch) sudo pacman -Sy ;;
    opensuse) sudo zypper refresh ;;
    *) echo "  (skip: unsupported package manager)" ;;
  esac
}

pkg_upgrade() {
  case "$PKG_FAMILY" in
    debian) sudo apt upgrade -y ;;
    fedora) sudo dnf -y upgrade ;;
    arch) sudo pacman -Syu --noconfirm ;;
    opensuse) sudo zypper update -y ;;
    *) echo "  (skip: unsupported package manager)" ;;
  esac
}

# pkg_install pkg1 pkg2 ...
pkg_install() {
  if [[ $# -eq 0 ]]; then return 0; fi
  case "$PKG_FAMILY" in
    debian) sudo apt install -y "$@" ;;
    fedora) sudo dnf install -y "$@" ;;
    arch) sudo pacman -S --needed --noconfirm "$@" ;;
    opensuse) sudo zypper install -y "$@" ;;
    *) echo "  (skip: don't know how to install '$*' on this distro)"; return 1 ;;
  esac
}

# pkg_installed pkgname -> returns 0 if installed
pkg_installed() {
  case "$PKG_FAMILY" in
    debian) dpkg -s "$1" >/dev/null 2>&1 ;;
    fedora) rpm -q "$1" >/dev/null 2>&1 ;;
    arch) pacman -Qi "$1" >/dev/null 2>&1 ;;
    opensuse) rpm -q "$1" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

ensure_flatpak() {
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "  Installing flatpak..."
    pkg_install flatpak
  fi
  if ! flatpak remote-list 2>/dev/null | grep -q flathub; then
    echo "  Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
}

flatpak_install() {
  # flatpak_install <app-id>
  if flatpak list --app 2>/dev/null | grep -q "$1"; then
    echo "  $1 already installed via Flatpak, skipping."
    return 0
  fi
  flatpak install -y flathub "$1"
}
