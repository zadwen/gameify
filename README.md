# gameify

Point this at pretty much any Linux distro and it analyzes your system, then
installs and configures what's needed to turn it into a gaming-ready desktop
— the way Nobara does out of the box for Fedora, but for any distro.

## What "smart" means here

Rather than a script hardcoded for one distro, `gameify.sh`:

1. **Reads `/etc/os-release`** to figure out your distro family (Debian/Ubuntu,
   Fedora/Nobara, Arch/Manjaro, or openSUSE) and picks the matching package
   manager (`apt`, `dnf`, `pacman`, `zypper`).
2. **Runs `lspci`** to detect your actual GPU(s) — including hybrid laptops
   with both an integrated and discrete GPU — instead of asking you to know
   which driver you need.
3. **Checks what's already installed** before doing anything, so it's safe
   to run more than once and won't fight with packages you already have.
4. **Prefers native packages** where they're reliable across versions
   (drivers, Wine, GameMode), and **falls back to Flatpak** for apps where
   package names are inconsistent between distros (Lutris, ProtonUp-Qt,
   Heroic) — so it doesn't break trying to guess a name that doesn't exist
   on your system.
5. **Prints a system report first** (distro, kernel, CPU, GPU, RAM, disk
   space, Secure Boot status, session type) so you know exactly what it saw
   before it changes anything.

## Supported distros

| Family | Examples | Support level |
|---|---|---|
| Debian/Ubuntu | Ubuntu, Zorin, Mint, Pop!_OS, Debian | Full |
| Fedora | Fedora, Nobara, Rocky, Alma | Full |
| Arch | Arch, Manjaro, EndeavourOS | Full |
| openSUSE | Leap, Tumbleweed | Best-effort — NVIDIA/Steam setup on openSUSE needs extra community repos that vary by version, so the script tells you what it did and points to the official guide if it can't finish automatically |

## Usage

```bash
git clone https://github.com/yourname/gameify.git
cd gameify
chmod +x gameify.sh detect.sh pkgmanager.sh drivers.sh gaming-stack.sh tweaks.sh
./gameify.sh
```

Run as a normal user — it calls `sudo` itself only for the specific commands
that need it, and tells you before each one.

## What it installs

- **Drivers**: NVIDIA / AMD / Intel, matched to what it detected (or pick
  manually)
- **Gaming stack**: Steam, Wine, GameMode, Lutris, MangoHud, ProtonUp-Qt,
  optionally Heroic Games Launcher
- **Tweaks (optional)**: raised `vm.max_map_count` for certain Proton/UE
  titles, adds your user to the `gamemode` group

## Project layout

```
gameify.sh          entry point — report, menu, orchestration
detect.sh        distro/GPU/CPU/session detection + system report
pkgmanager.sh     apt/dnf/pacman/zypper abstraction + Flatpak helpers
drivers.sh        per-distro, per-vendor driver install logic
gaming-stack.sh   Steam/Wine/GameMode/Lutris/MangoHud/ProtonUp-Qt/Heroic
tweaks.sh         optional sysctl + group tweaks
```

## Disclaimer

This installs real drivers and packages, and on Fedora/openSUSE may add
third-party repos (RPM Fusion / NVIDIA community repo) required for NVIDIA
and Steam. Everything it runs is plain `apt`/`dnf`/`pacman`/`zypper`/`flatpak`
— read `lib/*.sh` before running if you want to see exactly what it does.
Safe to re-run at any time.

## License

MIT — see `LICENSE`.
