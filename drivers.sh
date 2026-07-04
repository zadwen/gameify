#!/usr/bin/env bash
# lib/drivers.sh — GPU driver install, adapted per distro family
set -euo pipefail

_install_nvidia_debian() {
  if command -v ubuntu-drivers >/dev/null 2>&1; then
    echo "  Ubuntu-based system detected — using ubuntu-drivers autoinstall (auto-picks the right version)."
    sudo ubuntu-drivers autoinstall
  else
    echo "  Plain Debian detected. This needs the 'contrib' and 'non-free' repos enabled"
    echo "  in /etc/apt/sources.list before this will work. Attempting install anyway..."
    pkg_install nvidia-driver firmware-misc-nonfree || {
      echo "  Install failed — most likely contrib/non-free isn't enabled yet."
      echo "  See: https://wiki.debian.org/NvidiaGraphicsDrivers"
      return 1
    }
  fi
}

_install_nvidia_fedora() {
  if ! dnf repolist 2>/dev/null | grep -qi rpmfusion-nonfree; then
    echo "  Enabling RPM Fusion (free + nonfree) — required for NVIDIA on Fedora..."
    local fedver
    fedver="$(rpm -E %fedora)"
    pkg_install \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedver}.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedver}.noarch.rpm"
  else
    echo "  RPM Fusion already enabled (Nobara ships with this by default)."
  fi
  pkg_install akmod-nvidia xorg-x11-drv-nvidia-cuda
  echo "  Kernel module will build via akmods — this can take a few minutes on first boot."
}

_install_nvidia_arch() {
  echo "  Installing NVIDIA driver + utils via pacman..."
  pkg_install nvidia nvidia-utils nvidia-settings
}

_install_nvidia_opensuse() {
  echo "  openSUSE NVIDIA install varies by version (Leap vs Tumbleweed) and needs a"
  echo "  community repo added first. Attempting the common Tumbleweed path..."
  sudo zypper addrepo --refresh https://download.nvidia.com/opensuse/tumbleweed nvidia-repo 2>/dev/null || true
  sudo zypper refresh || true
  pkg_install x11-video-nvidiaG06 || {
    echo "  Automatic install didn't complete. Follow the official guide instead:"
    echo "  https://en.opensuse.org/SDB:NVIDIA_drivers"
    return 1
  }
}

install_nvidia() {
  echo "==> Installing NVIDIA driver..."
  case "$PKG_FAMILY" in
    debian) _install_nvidia_debian ;;
    fedora) _install_nvidia_fedora ;;
    arch) _install_nvidia_arch ;;
    opensuse) _install_nvidia_opensuse ;;
    *) echo "  Unsupported distro family for automatic NVIDIA install."; return 1 ;;
  esac
}

install_amd() {
  echo "==> Installing/updating AMD graphics stack (Mesa + Vulkan)..."
  case "$PKG_FAMILY" in
    debian) pkg_install mesa-vulkan-drivers libgl1-mesa-dri firmware-amd-graphics vulkan-tools ;;
    fedora) pkg_install mesa-vulkan-drivers mesa-dri-drivers vulkan-tools ;;
    arch) pkg_install vulkan-radeon mesa vulkan-tools ;;
    opensuse) pkg_install Mesa-vulkan-device-select vulkan-tools ;;
    *) echo "  Unsupported distro family for automatic AMD install."; return 1 ;;
  esac
  echo "  Note: the amdgpu kernel driver itself is already built into the Linux kernel —"
  echo "  this just installs the userspace Mesa/Vulkan pieces games actually talk to."
}

install_intel() {
  echo "==> Installing Intel graphics stack (Mesa + media driver)..."
  case "$PKG_FAMILY" in
    debian) pkg_install mesa-vulkan-drivers intel-media-va-driver vulkan-tools ;;
    fedora) pkg_install mesa-vulkan-drivers intel-media-driver vulkan-tools ;;
    arch) pkg_install vulkan-intel intel-media-driver vulkan-tools ;;
    opensuse) pkg_install Mesa-vulkan-device-select libva-intel-driver vulkan-tools ;;
    *) echo "  Unsupported distro family for automatic Intel install."; return 1 ;;
  esac
}

# Installs drivers for every vendor detected automatically (used in --auto mode)
install_detected_drivers() {
  local vendors="$1"
  for v in $vendors; do
    case "$v" in
      nvidia) install_nvidia ;;
      amd) install_amd ;;
      intel) install_intel ;;
    esac
  done
}

drivers_menu() {
  local detected="$1"
  echo ""
  echo "Detected GPU(s): ${detected:-none found}"
  echo "Which driver(s) do you want to install?"
  select opt in "Install detected ($detected)" "NVIDIA only" "AMD only" "Intel only" "Skip"; do
    case "$REPLY" in
      1) install_detected_drivers "$detected"; break ;;
      2) install_nvidia; break ;;
      3) install_amd; break ;;
      4) install_intel; break ;;
      5) echo "Skipping driver install."; break ;;
      *) echo "Invalid choice, pick a number from the list." ;;
    esac
  done
}
