#!/bin/sh
# Kocmoc OS Wayland session entry point (started by greetd).
export XDG_CURRENT_DESKTOP=Kocmoc:wlroots
export XDG_SESSION_DESKTOP=kocmoc
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM="wayland;xcb"
export _JAVA_AWT_WM_NONREPARENTING=1
# Kocmoc defaults for foot, fuzzel, GTK… live in /etc/xdg/kocmoc (no clashes with package files).
export XDG_CONFIG_DIRS="/etc/xdg/kocmoc:${XDG_CONFIG_DIRS:-/etc/xdg}"
xdg-user-dirs-update >/dev/null 2>&1 || true

# Power users may hand-maintain ~/.config/labwc; respect it completely.
if [ -f "$HOME/.config/labwc/rc.xml" ]; then
  exec labwc
fi
# Otherwise render the Kocmoc config (system defaults + user settings).
/usr/lib/kocmoc/kocmoc-labwc-gen
exec labwc -C "${XDG_CACHE_HOME:-$HOME/.cache}/kocmoc/labwc"
