# Changelog

All notable changes to gameify are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versioning is
[SemVer](https://semver.org/)-ish (0.x = pre-1.0, breaking changes possible
between minor versions until a 1.0 release).

## [0.3.0] — Reliability & safety pass

### Added
- `--dry-run` flag on `gameify.sh` — every mutating operation (package
  installs, sysctl writes, file writes, downloads, cron changes) prints
  what it would do instead of doing it. Threaded through `pkgmanager.sh`'s
  core `pkg_install`/`pkg_update`/`pkg_upgrade`/`flatpak_install` and every
  module's own mutating calls.
- `--version` / `--help` flags on `gameify.sh`, backed by a `VERSION` file.
- CI (`.github/workflows/ci.yml`): `shellcheck` + `bash -n` on every push
  and PR, across all shell scripts in the repo.
- This changelog.

### Changed
- Fixed the two outstanding `shellcheck` warnings (unused `hybrid` local in
  `detect.sh`, unused `opt` in `kernel.sh`'s `select` — now matches on
  `$opt` instead of `$REPLY`, consistent with `drivers.sh`).

### Notes
- `heal.sh`'s error-signature patterns are heuristic pattern matches
  against known Linux-gaming failure modes — they haven't all been
  validated against real-world log samples yet. Each is documented in
  README.md with what it looks for and what it does; see ROADMAP.md for
  where this is heading (an expanded, community-informed signature set).

## [0.2.0] — Smart analyzer, tiers, auto-healing

### Added
- Full hardware/session profiling in `detect.sh`: CPU, GPU(s), RAM, disk
  type, monitor refresh rate, Secure Boot state, kernel version, session
  type (X11/Wayland).
- Hybrid-GPU (Optimus/PRIME) default-renderer diagnosis + `prime-run`
  wrapper in `drivers.sh`.
- Optional performance kernels (XanMod/Liquorix/linux-zen) in `kernel.sh`,
  with a Secure Boot pre-check and explanation before installing.
- Proton-GE auto-install/update, Gamescope, vkBasalt, and per-game Proton
  override (direct `config.vdf` edits with automatic backup) in
  `gaming-stack.sh`.
- Bug auto-healing (`heal.sh`): scans `journalctl` + Steam logs for known
  error signatures and applies safe fixes automatically.
- Everyday app installs (`apps.sh`): Discord/OBS/Spotify via Flatpak,
  Battle.net/EA App via Lutris's own install scripts.
- Self-managed weekly cron job: `update.sh --install-cron` / `--remove-cron`.
- **Standard / Advanced / Experimental tiers** across every module, saved
  to `~/.config/gameify/tiers.conf`, changeable via `./gameify.sh --tiers`.

## [0.1.0] — Initial modular script

- Distro/CPU/GPU/RAM/disk detection and system report (`detect.sh`).
- Per-distro driver install with hybrid-GPU/PRIME awareness (`drivers.sh`).
- Core gaming stack: Steam, Wine, GameMode, Lutris, MangoHud, ProtonUp-Qt,
  Heroic (`gaming-stack.sh`).
- Basic tweaks: Vulkan check, `vm.max_map_count`, gamemode group,
  Wine-prefix repair (`tweaks.sh`).
- `pkgmanager.sh` abstraction over apt/dnf/pacman/zypper + Flatpak.
