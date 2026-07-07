#!/usr/bin/env bash
# detect_gpus.sh — physical GPU detection, fixed two ways:
#
# 1. Counts by PCI bus address via lspci, not by /dev/dri device-node count.
#    A single GPU normally creates *two* nodes under /dev/dri/ — cardN (the
#    display/KMS node) and renderDXXX (the render-only node) — so counting
#    files there over-counts by roughly 2x.
#
# 2. Identifies vendor by the numeric PCI vendor ID (e.g. [8086:xxxx] for
#    Intel), not by grepping the human-readable name for substrings like
#    "ati". That text-substring approach has a real, confirmed bug: the
#    class name lspci prints for *every* GPU — "VGA compatible controller"
#    — itself contains the letters "ati" (comp-ATI-ble), and "Corporation"
#    does too (corpor-ATI-on). A pattern like `grep -Eqi 'amd|ati|radeon'`
#    matches that on essentially any GPU line, regardless of actual vendor.
#    Matching the numeric vendor ID instead sidesteps this entirely.
set -euo pipefail

# Known PCI vendor IDs for the vendors we care about.
readonly PCI_VENDOR_INTEL="8086"
readonly PCI_VENDOR_AMD="1002"     # AMD-owned GPUs still use ATI Technologies' old ID
readonly PCI_VENDOR_NVIDIA_NEW="10de"
readonly PCI_VENDOR_NVIDIA_OLD="12d2"  # legacy, pre-2000s NVIDIA cards; harmless to keep

detect_gpu_lines() {
  if ! command -v lspci >/dev/null 2>&1; then
    echo "lspci not found — install the 'pciutils' package and re-run." >&2
    return 1
  fi
  # -D: always print the full domain:bus:device.function (stable unique
  #     key for de-duplication, even on single-domain systems).
  # -nn: human-readable name AND numeric [vendor:device] IDs together.
  lspci -Dnn 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller'
}

# Prints one de-duplicated line per physical GPU: "<bus> <vendor_id> <name>"
_unique_gpu_records() {
  local -A seen_bus=()
  local line bus vendor_id name
  while IFS= read -r line; do
    bus="$(awk '{print $1}' <<< "$line")"
    # Defensive: lspci already emits one line per PCI function, so this
    # should never actually trigger, but guarantees "one physical device,
    # one count" even if that ever changes.
    [[ -n "${seen_bus[$bus]:-}" ]] && continue
    seen_bus[$bus]=1

    vendor_id="$(grep -oE '\[[0-9a-f]{4}:[0-9a-f]{4}\]' <<< "$line" | tail -n1 | tr -d '[]' | cut -d: -f1)"
    name="$(sed -E 's/^\S+ [^:]+: (.*) \[[0-9a-f]{4}:[0-9a-f]{4}\].*/\1/' <<< "$line")"

    echo "${bus} ${vendor_id} ${name}"
  done < <(detect_gpu_lines)
}

# Total count + a human-readable listing of physical GPUs.
detect_physical_gpus() {
  local -a records=()
  local rec
  while IFS= read -r rec; do
    [[ -n "$rec" ]] && records+=("$rec")
  done < <(_unique_gpu_records)

  echo "Physical GPU(s) detected: ${#records[@]}"
  for rec in "${records[@]}"; do
    local bus vid name
    bus="$(cut -d' ' -f1 <<< "$rec")"
    vid="$(cut -d' ' -f2 <<< "$rec")"
    name="$(cut -d' ' -f3- <<< "$rec")"
    printf '  - [%s] (vendor id: %s) %s\n' "$bus" "$vid" "$name"
  done
}

# Space-separated vendor tags, e.g. "intel" or "nvidia intel" — matched by
# numeric PCI vendor ID, immune to the text-substring false-positive bug.
detect_gpu_vendor_tags() {
  local -a records=()
  local rec
  while IFS= read -r rec; do
    [[ -n "$rec" ]] && records+=("$rec")
  done < <(_unique_gpu_records)

  local tags="" vid
  for rec in "${records[@]}"; do
    vid="$(cut -d' ' -f2 <<< "$rec")"
    case "$vid" in
      "$PCI_VENDOR_INTEL") tags+="intel " ;;
      "$PCI_VENDOR_AMD") tags+="amd " ;;
      "$PCI_VENDOR_NVIDIA_NEW"|"$PCI_VENDOR_NVIDIA_OLD") tags+="nvidia " ;;
    esac
  done
  if [[ -z "$tags" ]]; then echo "unknown"; else echo "$tags" | xargs; fi
}

detect_hybrid_gpu() {
  local count
  count=$(detect_gpu_vendor_tags | wc -w)
  [[ "$count" -ge 2 ]]
}

detect_physical_gpus
echo ""
echo "Vendor tags: $(detect_gpu_vendor_tags)"
