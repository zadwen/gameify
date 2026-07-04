#!/usr/bin/env bash
# lib/gaming-stack.sh — core gaming apps, adapted per distro family
set -euo pipefail

enable_32bit() {
  echo "==> Enabling 32-bit library support (needed for many older/Proton games)..."
  case "$PKG_FAMILY" in
    debian)
      sudo dpkg --add-architecture i386
      pkg_update
      ;;
    arch)
      if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
        echo "  Enabling [multilib] repo in /etc/pacman.conf..."
        sudo sed -i "/^#\[multilib\]/,/^#Include/ s/^#//" /etc/pacman.conf
        pkg_update
      else
        echo "  [multilib] already enabled."
      fi
      ;;
    fedora|opensuse)
      echo "  Nothing to do — Mesa on this distro already ships 32-bit compat as needed."
      ;;
    *) echo "  (skip: unsupported distro family)" ;;
  esac
}

install_steam() {
  echo "==> Installing Steam..."
  if command -v steam >/dev/null 2>&1; then
    echo "  Steam already installed, skipping."
    return 0
  fi
  case "$PKG_FAMILY" in
    debian) pkg_install steam-installer || pkg_install steam ;;
    fedora)
      if ! dnf repolist 2>/dev/null | grep -qi rpmfusion-nonfree; then
        echo "  Steam on Fedora needs RPM Fusion nonfree — installing that first..."
        local fedver; fedver="$(rpm -E %fedora)"
        pkg_install "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedver}.noarch.rpm"
      fi
      pkg_install steam
      ;;
    arch) pkg_install steam ;;
    opensuse)
      echo "  Steam on openSUSE needs the Packman repo. Falling back to Flatpak instead"
      echo "  to keep this simple and reliable:"
      ensure_flatpak
      flatpak_install com.valvesoftware.Steam
      ;;
    *) ensure_flatpak; flatpak_install com.valvesoftware.Steam ;;
  esac
}

install_wine() {
  echo "==> Installing Wine..."
  if pkg_installed wine 2>/dev/null || command -v wine >/dev/null 2>&1; then
    echo "  Wine already installed, skipping."
    return 0
  fi
  case "$PKG_FAMILY" in
    debian) pkg_install wine winetricks ;;
    fedora) pkg_install wine winetricks ;;
    arch) pkg_install wine winetricks ;;
    opensuse) pkg_install wine winetricks ;;
    *) echo "  (skip: unsupported distro family)" ;;
  esac
}

install_gamemode() {
  echo "==> Installing GameMode (performance daemon)..."
  if pkg_installed gamemode 2>/dev/null; then
    echo "  GameMode already installed, skipping."
    return 0
  fi
  pkg_install gamemode || echo "  GameMode package not found for this distro — skipping."
}

install_lutris() {
  echo "==> Installing Lutris (via Flatpak — consistent across every distro)..."
  ensure_flatpak
  flatpak_install net.lutris.Lutris
}

install_mangohud() {
  echo "==> Installing MangoHud (FPS/performance overlay)..."
  if pkg_installed mangohud 2>/dev/null; then
    echo "  MangoHud already installed, skipping."
    return 0
  fi
  pkg_install mangohud || {
    echo "  Native package not found — installing via Flatpak instead."
    ensure_flatpak
    flatpak_install org.freedesktop.Platform.VulkanLayer.MangoHud
  }
}

install_protonup() {
  echo "==> Installing ProtonUp-Qt (manage custom Proton-GE / Wine-GE builds)..."
  ensure_flatpak
  flatpak_install net.davidotek.pupgui2
}

install_heroic() {
  echo "==> Installing Heroic Games Launcher (Epic/GOG/Amazon on Linux)..."
  ensure_flatpak
  flatpak_install com.heroicgameslauncher.hgl
}

gaming_stack_menu() {
  echo ""
  echo "Core gaming stack: Steam, Wine, GameMode, Lutris, MangoHud, ProtonUp-Qt"
  read -r -p "Also install Heroic Games Launcher (Epic/GOG/Amazon)? [y/N] " want_heroic
  read -r -p "Proceed with install? [Y/n] " answer
  answer=${answer:-Y}
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Skipping gaming stack install."
    return
  fi
  enable_32bit
  install_steam
  install_wine
  install_gamemode
  install_lutris
  install_mangohud
  install_protonup
  if [[ "$want_heroic" =~ ^[Yy]$ ]]; then
    install_heroic
  fi
  echo "==> Gaming stack installed."
}
