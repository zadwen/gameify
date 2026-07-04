#!/usr/bin/env bash
# lib/tweaks.sh — optional, well-known gaming-related tweaks (distro-agnostic)
set -euo pipefail

tweak_vm_max_map_count() {
  echo "==> Raising vm.max_map_count (needed by some Proton/Steam titles, e.g. certain UE4/5 games)..."
  local conf="/etc/sysctl.d/80-gamecompat.conf"
  echo "vm.max_map_count=2147483642" | sudo tee "$conf" >/dev/null
  sudo sysctl --system >/dev/null
}

tweak_gamemode_group() {
  echo "==> Adding your user to the 'gamemode' group so GameMode can adjust performance..."
  if getent group gamemode >/dev/null 2>&1; then
    sudo usermod -aG gamemode "$USER" || true
    echo "    (log out/in or reboot for the group change to apply)"
  else
    echo "    'gamemode' group doesn't exist yet — install GameMode first."
  fi
}

system_tweaks_menu() {
  echo ""
  read -r -p "Apply optional system tweaks (vm.max_map_count, gamemode group)? [Y/n] " answer
  answer=${answer:-Y}
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Skipping system tweaks."
    return
  fi
  tweak_vm_max_map_count
  tweak_gamemode_group
  echo "==> Tweaks applied."
}
