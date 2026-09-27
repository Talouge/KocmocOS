# Kocmoc shell components (run by labwc through sh)
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE >/dev/null 2>&1 &
/usr/lib/kocmoc/kocmoc-display-apply >/dev/null 2>&1
kocmoc-wallpaper >/dev/null 2>&1 &
kocmoc-panel >/dev/null 2>&1 &
mako -c /etc/xdg/kocmoc/mako.ini >/dev/null 2>&1 &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &
kocmoc-idle >/dev/null 2>&1 &
/usr/lib/kocmoc/kocmoc-live-welcome >/dev/null 2>&1 &
