#!/bin/bash
# Build and install an AUR package the Arch way: clone, REVIEW, makepkg -si.
# Runs as the normal user; makepkg asks for sudo only for the final install.
set -uo pipefail
pkg="${1:-}"
pause() { echo; read -rp "Press Enter to close…" _; }
trap pause EXIT
[[ "$pkg" =~ ^[a-z0-9@._+-]+$ ]] || { echo "Invalid package name"; exit 1; }
[[ $EUID -eq 0 ]] && { echo "Do not build AUR packages as root."; exit 1; }
printf '\e[1mAUR · %s\e[0m\n' "$pkg"
echo "AUR packages are user-produced content. Any use of the provided files is at your own risk."
if ! pacman -T base-devel git >/dev/null 2>&1; then
  echo "Build tools (base-devel, git) are required."
  sudo pacman -S --needed base-devel git || exit 1
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"; pause' EXIT
git clone --depth=1 "https://aur.archlinux.org/${pkg}.git" "$work/$pkg" || exit 1
cd "$work/$pkg" || exit 1
[[ -f PKGBUILD ]] || { echo "No PKGBUILD found: is the package name right?"; exit 1; }
echo; echo "Opening PKGBUILD for review (q to quit the viewer)…"; sleep 1
less PKGBUILD
read -rp "Build and install ${pkg}? [y/N] " ans
[[ "$ans" == [yY]* ]] || { echo "Cancelled."; exit 0; }
makepkg -si --needed
