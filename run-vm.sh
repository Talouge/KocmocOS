#!/usr/bin/env python3
"""Kocmoc Update Center: checkupdates + pacman -Syu with live progress and errors."""
import os
import sys
import time

_here = os.path.dirname(os.path.abspath(__file__))
for _p in (os.environ.get("KOCMOC_LIB"), "/usr/lib/kocmoc", os.path.join(_here, "..", "shell")):
    if _p and os.path.isdir(os.path.join(_p, "kocmoc")):
        sys.path.insert(0, _p)
        break

from kocmoc import pkg, proc, theme  # noqa: E402
from kocmoc.theme import GLib, Gtk, button, clear, hbox, label, vbox  # noqa: E402


class UpdateWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Update Center")
        self.set_default_size(760, 680)
        self.updates = []
        self.busy = False
        self._pulse = None
        header = Gtk.HeaderBar()
        header.set_title_widget(label("Update Center", "title", xalign=0.5))
        self.check_btn = button("Check now", self.check, "flat")
        header.pack_start(self.check_btn)
        self.set_titlebar(header)

        body = vbox(16, "page")
        hero = hbox(16, "card pad")
        self.state_title = label("Checking for updates…", "section-title", wrap=True)
        self.state_sub = label("", "dim small", wrap=True)
        t = vbox(4)
        t.set_hexpand(True)
        t.append(self.state_title)
        t.append(self.state_sub)
        hero.append(t)
        self.update_btn = button("Update all", self.confirm_update, "suggested", False)
        self.update_btn.set_valign(Gtk.Align.CENTER)
        hero.append(self.update_btn)
        body.append(hero)

        self.progress_box = vbox(6)
        self.stage = label("", "row-title")
        self.bar = Gtk.ProgressBar()
        self.progress_box.append(self.stage)
        self.progress_box.append(self.bar)
        self.progress_box.set_visible(False)
        body.append(self.progress_box)

        body.append(label("PACKAGES", "group-title"))
        sw = Gtk.ScrolledWindow(vexpand=True)
        self.list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        self.list.add_css_class("card")
        sw.set_child(self.list)
        body.append(sw)

        self.log = Gtk.TextView(editable=False, monospace=True, wrap_mode=Gtk.WrapMode.CHAR)
        lsw = Gtk.ScrolledWindow(min_content_height=150)
        lsw.set_child(self.log)
        exp = Gtk.Expander(label="Log")
        exp.set_child(lsw)
        body.append(exp)
        self.reboot_btn = button("Restart now", lambda: proc.spawn(["systemctl", "reboot"]), "suggested")
        self.reboot_btn.set_visible(False)
        body.append(self.reboot_btn)
        self.set_child(body)
        self.check()

    def check(self):
        if self.busy:
            return
        self.busy = True
        self.check_btn.set_sensitive(False)
        self.update_btn.set_sensitive(False)
        self.state_title.set_text("Checking for updates…")
        self.state_sub.set_text("Syncing package databases with Arch Linux mirrors.")
        proc.in_thread(pkg.refresh, self.show)

    def show(self, res):
        self.busy = False
        self.check_btn.set_sensitive(True)
        clear(self.list)
        if isinstance(res, Exception) or not res[0]:
            err = str(res) if isinstance(res, Exception) else res[2]
            self.state_title.set_text("Couldn't check for updates")
            self.state_sub.set_text(f"Are you online? Details: {err[:300]}")
            return
        self.updates = res[1]
        stamp = time.strftime("%H:%M")
        if not self.updates:
            self.state_title.set_text("Kocmoc OS is up to date")
            self.state_sub.set_text(f"Last checked at {stamp}.")
            self.list.append(label("No pending updates.", "dim pad"))
            return
        n = len(self.updates)
        self.state_title.set_text(f"{n} update{'s' if n != 1 else ''} available")
        crit = sorted(u["name"] for u in self.updates if u["name"] in pkg.REBOOT_PKGS)
        self.state_sub.set_text(f"Checked at {stamp}." + (f" Includes {', '.join(crit)}: a restart will be needed." if crit else ""))
        self.update_btn.set_sensitive(True)
        for u in self.updates:
            r = hbox(12, "row")
            n_l = label(u["name"], "row-title")
            n_l.set_hexpand(True)
            r.append(n_l)
            r.append(label(f"{u['old']}  →  {u['new']}", "dim small mono"))
            self.list.append(r)

    def confirm_update(self):
        detail = "Runs pacman -Syu. Keep the computer on and connected until it finishes."
        if proc.is_live():
            detail += "\n\nLive session: updates are kept in RAM only and may run out of space."
        theme.confirm(self, f"Install {len(self.updates)} updates?", detail, "Update", self.start)

    def start(self):
        self.busy = True
        self.check_btn.set_sensitive(False)
        self.update_btn.set_sensitive(False)
        self.progress_box.set_visible(True)
        self.reboot_btn.set_visible(False)
        self.stage.set_text("Downloading packages…")
        self.bar.set_fraction(0)
        self.log.get_buffer().set_text("")
        self._pulse = GLib.timeout_add(120, lambda: (self.bar.pulse(), True)[1])
        proc.stream(pkg.upgrade_cmd(), self.on_line, self.on_done)

    def on_line(self, line):
        buf = self.log.get_buffer()
        buf.insert(buf.get_end_iter(), line + "\n")
        m = pkg.PROGRESS_RE.match(line)
        if m:
            if self._pulse:
                GLib.source_remove(self._pulse)
                self._pulse = None
            self.bar.set_fraction(int(m.group(1)) / max(int(m.group(2)), 1))
            self.stage.set_text(m.group(3))
        elif line.startswith(":: Running post-transaction hooks"):
            self.stage.set_text("Finishing up (hooks, initramfs)…")

    def on_done(self, rc):
        if self._pulse:
            GLib.source_remove(self._pulse)
            self._pulse = None
        self.busy = False
        self.check_btn.set_sensitive(True)
        if rc == 0:
            self.bar.set_fraction(1)
            self.stage.set_text("System updated ✓")
            if any(u["name"] in pkg.REBOOT_PKGS for u in self.updates):
                self.reboot_btn.set_visible(True)
            self.check()
        else:
            self.stage.set_text("Update failed")
            buf = self.log.get_buffer()
            text = buf.get_text(buf.get_start_iter(), buf.get_end_iter(), False)
            hint = ""
            if "unable to lock database" in text:
                hint = "\n\nAnother package manager is running (or a stale /var/lib/pacman/db.lck exists)."
            elif "invalid or corrupted package" in text or "signature" in text:
                hint = "\n\nKeyring may be outdated: update archlinux-keyring first (sudo pacman -Sy archlinux-keyring)."
            theme.alert(self, "Update failed", (pkg.explain_rc(rc) or "\n".join(text.splitlines()[-10:])) + hint)
            self.update_btn.set_sensitive(bool(self.updates))


class App(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="os.kocmoc.UpdateCenter")

    def do_activate(self):
        if not self.get_active_window():
            theme.apply()
            UpdateWindow(self)
        self.get_active_window().present()


if __name__ == "__main__":
    sys.exit(App().run(sys.argv))
