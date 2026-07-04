#!/usr/bin/env bash
# lib/detect.sh — figure out what system we're actually on
set -euo pipefail

detect_distro_family() {
  local id="" id_like=""
  if [[ -f /etc/os-release ]]; then
    id="$(. /etc/os-release; echo "${ID:-}")"
    id_like="$(. /etc/os-release; echo "${ID_LIKE:-}")"
  fi
  local combined="$id $id_like"
  case "$combined" in
    *ubuntu*|*debian*|*mint*|*zorin*|*pop*|*elementary*|*neon*) echo "debian" ;;
    *fedora*|*rhel*|*centos*|*nobara*|*rocky*|*alma*) echo "fedora" ;;
    *arch*|*manjaro*|*endeavour*) echo "arch" ;;
    *suse*) echo "opensuse" ;;
    *) echo "unknown" ;;
  esac
}

distro_pretty_name() {
  if [[ -f /etc/os-release ]]; then
    (. /etc/os-release; echo "${PRETTY_NAME:-Unknown Linux}")
  else
    echo "Unknown Linux"
  fi
}

detect_gpu_lines() {
  if command -v lspci >/dev/null 2>&1; then
    lspci -nnk 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller' || true
  fi
}

# Prints space-separated vendor tags, e.g. "nvidia intel" for a hybrid laptop
detect_gpu_vendors() {
  local lines vendors=""
  lines="$(detect_gpu_lines)"
  if [[ -z "$lines" ]]; then
    echo "unknown"
    return
  fi
  if echo "$lines" | grep -qi nvidia; then vendors="$vendors nvidia"; fi
  if echo "$lines" | grep -Eqi 'amd|ati|radeon'; then vendors="$vendors amd"; fi
  if echo "$lines" | grep -qi intel; then vendors="$vendors intel"; fi
  if [[ -z "$vendors" ]]; then
    echo "unknown"
  else
    echo "$vendors" | xargs
  fi
}

detect_cpu_vendor() {
  if [[ -f /proc/cpuinfo ]]; then
    grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}'
  else
    echo "unknown"
  fi
}

detect_session_type() {
  echo "${XDG_SESSION_TYPE:-unknown}"
}

detect_secure_boot() {
  if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state 2>/dev/null | head -n1 || echo "unknown"
  else
    echo "unknown (mokutil not installed)"
  fi
}

detect_ram() {
  free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "unknown"
}

detect_disk_free_root() {
  df -h / 2>/dev/null | awk 'NR==2 {print $4 " free"}' || echo "unknown"
}

print_system_report() {
  local family gpus cpu session secureboot ram disk

  family="$(detect_distro_family)"
  gpus="$(detect_gpu_vendors)"
  cpu="$(detect_cpu_vendor)"
  session="$(detect_session_type)"
  secureboot="$(detect_secure_boot)"
  ram="$(detect_ram)"
  disk="$(detect_disk_free_root)"

  echo "=================================================="
  echo " System Report"
  echo "=================================================="
  printf "  %-18s %s\n" "Distro:" "$(distro_pretty_name)"
  printf "  %-18s %s\n" "Family:" "$family"
  printf "  %-18s %s\n" "Kernel:" "$(uname -r)"
  printf "  %-18s %s\n" "CPU vendor:" "$cpu"
  printf "  %-18s %s\n" "GPU(s) detected:" "$gpus"
  printf "  %-18s %s\n" "Session type:" "$session"
  printf "  %-18s %s\n" "Secure Boot:" "$secureboot"
  printf "  %-18s %s\n" "RAM:" "$ram"
  printf "  %-18s %s\n" "Free disk (/):" "$disk"
  echo "=================================================="

  if [[ "$family" == "unknown" ]]; then
    echo ""
    echo "WARNING: could not identify your distro family from /etc/os-release."
    echo "This tool supports Debian/Ubuntu, Fedora/Nobara, Arch/Manjaro, and openSUSE."
    echo "Continuing may not work correctly."
  fi

  if [[ "$gpus" == "unknown" ]]; then
    echo ""
    echo "WARNING: could not detect your GPU via lspci. Driver install will be skipped"
    echo "unless you pick one manually."
  fi

  if [[ "$secureboot" == *"enabled"* ]]; then
    echo ""
    echo "NOTE: Secure Boot is enabled. NVIDIA/AMD kernel modules (DKMS/akmods) may"
    echo "need to be signed, or you'll be prompted to enroll a MOK key on reboot."
  fi
}
