#!/usr/bin/env python3
"""Kocmoc App Store: a native front-end for real pacman transactions (+ AUR builds).

Search uses a freshly synced private copy of the sync DBs (no root needed).
Install / remove / update run pacman through kocmoc-helper + pkexec.
AUR packages are built with makepkg in a visible terminal after PKGBUILD review.
"""
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
for _p in (os.environ.get("KOCMOC_LIB"), "/usr/lib/kocmoc", os.path.join(_here, "..", "shell")):
    if _p and os.path.isdir(os.path.join(_p, "kocmoc")):
        sys.path.insert(0, _p)
        break

from kocmoc import pkg, proc, theme  # noqa: E402
from kocmoc.theme import Gio, GLib, Gtk, button, clear, hbox, label, vbox  # noqa: E402

FEATURED = ["firefox", "chromium", "thunderbird", "libreoffice-fresh", "gimp", "inkscape", "krita",
            "vlc", "mpv", "obs-studio", "audacity", "kdenlive", "telegram-desktop", "keepassxc",
            "transmission-gtk", "neovim", "htop", "blender"]


class StoreWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="App Store")
        self.set_default_size(1120, 740)
        self.mode = "discover"
        self.busy = False
        self.selected = None
        self._search_timer = None
        self.installed_cache = []

        header = Gtk.HeaderBar()
        self.search = Gtk.SearchEntry(placeholder_text="Search Arch Linux packages")
        self.search.set_size_request(420, -1)
        self.search.connect("search-changed", self.on_search)
        header.set_title_widget(self.search)
        tabs = hbox(0, "linked")
        first = None
        for key, text in (("discover", "Discover"), ("installed", "Installed"), ("aur", "AUR")):
            b = Gtk.ToggleButton(label=text)
            if first:
                b.set_group(first)
            else:
                first = b
                b.set_active(True)
            b.connect("toggled", lambda w, k=key: w.get_active() and self.set_mode(k))
            tabs.append(b)
        header.pack_start(tabs)
        upd = button("Updates", lambda: proc.spawn(["kocmoc-update-center"]), "flat")
        header.pack_end(upd)
        self.set_titlebar(header)

        root = vbox(0)
        paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL, position=480, vexpand=True)
        left = Gtk.ScrolledWindow()
        left.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.results = Gtk.ListBox(selection_mode=Gtk.SelectionMode.SINGLE)
        self.results.add_css_class("results")
        self.results.connect("row-selected", self.on_select)
        left.set_child(self.results)
        paned.set_start_child(left)
        right = Gtk.ScrolledWindow()
        self.details = vbox(14, "page")
        right.set_child(self.details)
        paned.set_end_child(right)
        root.append(paned)

        self.bottom = vbox(6, "opbar")
        self.op_label = label("", "row-title")
        self.bar = Gtk.ProgressBar()
        self.log_view = Gtk.TextView(editable=False, monospace=True, wrap_mode=Gtk.WrapMode.CHAR)
        self.log_view.add_css_class("mono")
        sw = Gtk.ScrolledWindow(min_content_height=160)
        sw.set_child(self.log_view)
        exp = Gtk.Expander(label="Details")
        exp.set_child(sw)
        self.bottom.append(self.op_label)
        self.bottom.append(self.bar)
        self.bottom.append(exp)
        self.bottom.set_visible(False)
        root.append(self.bottom)
        self.set_child(root)

        self.placeholder("Refreshing package database…", "Fetching the latest package lists from Arch Linux mirrors.")
        proc.in_thread(pkg.refresh, self.after_refresh)

    # ---------------------------------------------------------------- listing
    def placeholder(self, title, sub=""):
        clear(self.details)
        self.details.append(label(title, "section-title", wrap=True))
        if sub:
            self.details.append(label(sub, "dim", wrap=True))

    def after_refresh(self, res):
        if isinstance(res, Exception) or not res[0]:
            err = res[2] if not isinstance(res, Exception) else str(res)
            self.placeholder("Offline mode", "Could not refresh package lists (" + err[:200] +
                             "). Results may be outdated or empty until you're online.")
        else:
            self.placeholder("Find software", "Search thousands of Arch Linux packages, or pick something below.")
        self.load_list()

    def set_mode(self, mode):
        self.mode = mode
        self.search.set_placeholder_text({"discover": "Search Arch Linux packages", "installed": "Filter installed packages",
                                          "aur": "Search the Arch User Repository"}[mode])
        self.load_list()

    def on_search(self, *_):
        if self._search_timer:
            GLib.source_remove(self._search_timer)
        self._search_timer = GLib.timeout_add(350, lambda: (self.load_list(), setattr(self, "_search_timer", None), False)[2])

    def load_list(self):
        q = self.search.get_text().strip()
        mode = self.mode
        if mode == "discover":
            fn = (lambda: pkg.search(q)) if len(q) >= 2 else (lambda: [dict(pkg.info(n), name=n) for n in FEATURED])
        elif mode == "installed":
            fn = pkg.installed_explicit
        else:
            if len(q) < 2:
                self.fill([])
                self.placeholder("Arch User Repository", "Community-maintained build scripts. They are NOT reviewed by "
                                 "Arch Linux or Kocmoc OS: read the PKGBUILD before installing. Type at least 2 letters.")
                return
            fn = lambda: pkg.aur_search(q)
        proc.in_thread(fn, lambda res, m=mode, qq=q: self.fill(res, qq) if m == self.mode else None)

    def fill(self, items, q=""):
        clear(self.results)
        if isinstance(items, Exception):
            self.results.append(label(f"Error: {items}", "dim pad", wrap=True))
            return
        norm = []
        for it in items:
            if "Name" in it:  # pacman -Si dict from FEATURED
                if not it.get("Version"):
                    continue
                it = {"name": it["name"], "version": it["Version"], "repo": it.get("Repository", ""),
                      "desc": it.get("Description", ""), "installed": bool(it.get("_local")), "source": "repo"}
            elif "version" not in it:
                continue
            norm.append(it)
        if self.mode == "installed" and q:
            norm = [i for i in norm if q.lower() in i["name"]]
        for it in norm[:300]:
            r = Gtk.ListBoxRow()
            r.item = it
            box = vbox(3, "result")
            top = hbox(8)
            top.append(label(it["name"], "row-title"))
            top.append(label(it["version"], "dim small"))
            sp = label("")
            sp.set_hexpand(True)
            top.append(sp)
            if it.get("installed"):
                top.append(label("INSTALLED", "badge ok"))
            if it.get("repo"):
                top.append(label(it["repo"], "badge"))
            box.append(top)
            if it.get("desc"):
                d = label(it["desc"], "dim small", wrap=True)
                d.set_max_width_chars(60)
                box.append(d)
            r.set_child(box)
            self.results.append(r)
        if not norm:
            self.results.append(label("Nothing found.", "dim pad"))

    # ---------------------------------------------------------------- details
    def on_select(self, _lb, r):
        if r is None or not hasattr(r, "item"):
            return
        it = r.item
        self.selected = it
        self.placeholder(it["name"], "Loading…")
        if it["source"] == "aur":
            proc.in_thread(lambda: pkg.local_version(it["name"]), lambda v: self.show_aur(it, v))
        else:
            proc.in_thread(lambda: pkg.info(it["name"]), lambda inf: self.show_repo(it, inf))

    def _kv(self, rows):
        grid = Gtk.Grid(column_spacing=24, row_spacing=6)
        for i, (k, v) in enumerate(rows):
            grid.attach(label(k, "dim small"), 0, i, 1, 1)
            grid.attach(label(v or "–", "small", wrap=True, selectable=True), 1, i, 1, 1)
        return grid

    def show_repo(self, it, inf):
        if self.selected is not it:
            return
        clear(self.details)
        if isinstance(inf, Exception) or not inf:
            self.placeholder(it["name"], "No information available (package list may be outdated).")
            return
        local, remote = inf.get("_local"), inf.get("Version")
        self.details.append(label(inf.get("Name", it["name"]), "page-title"))
        self.details.append(label(inf.get("Description", ""), "dim", wrap=True))
        if local and remote and local != remote and inf.get("Repository") != "local":
            status = f"Installed {local} · update to {remote} available"
        elif local:
            status = f"Installed · {local}"
        else:
            status = "Not installed"
        self.details.append(label(status, "badge ok" if local else "badge"))
        acts = hbox(8)
        if local:
            for f in pkg.desktop_files(it["name"])[:1]:
                acts.append(button("Open", lambda f=f: Gio.DesktopAppInfo.new_from_filename(f).launch([], None), "suggested"))
            if remote and local != remote and inf.get("Repository") != "local":
                acts.append(button("Update", lambda: self.operate("update", it["name"])))
            acts.append(button("Remove", lambda: self.operate("remove", it["name"]), "danger"))
        else:
            acts.append(button("Install", lambda: self.operate("install", it["name"], inf), "suggested"))
        self.details.append(acts)
        deps = inf.get("Depends On", "None")
        self.details.append(self._kv([
            ("Version", remote or local), ("Repository", inf.get("Repository")),
            ("Download size", inf.get("Download Size")), ("Installed size", inf.get("Installed Size")),
            ("License", inf.get("Licenses")), ("Maintainer", inf.get("Packager")),
            ("Website", inf.get("URL")), ("Dependencies", "none" if deps == "None" else f"{len(deps.split())} packages"),
            ("Built", inf.get("Build Date"))]))

    def show_aur(self, it, local):
        if self.selected is not it:
            return
        clear(self.details)
        self.details.append(label(it["name"], "page-title"))
        self.details.append(label(it["desc"], "dim", wrap=True))
        warn = label("AUR packages are user-submitted build scripts, not reviewed by Arch Linux or Kocmoc OS. "
                     "A terminal will open so you can read the PKGBUILD before anything is built.", "warn small", wrap=True)
        self.details.append(warn)
        acts = hbox(8)
        if local:
            acts.append(button("Rebuild / update", lambda: proc.spawn(["foot", "-T", f"AUR · {it['name']}", "-e", "kocmoc-aur-install", it["name"]])))
            acts.append(button("Remove", lambda: self.operate("remove", it["name"]), "danger"))
        else:
            acts.append(button("Review & build…", lambda: proc.spawn(["foot", "-T", f"AUR · {it['name']}", "-e", "kocmoc-aur-install", it["name"]]), "suggested"))
        self.details.append(acts)
        self.details.append(self._kv([("Version", it["version"]), ("Installed", local or "no"),
                                      ("Maintainer", it["maintainer"]), ("Votes", str(it["votes"])),
                                      ("Flagged out-of-date", "yes" if it["outdated"] else "no"), ("Website", it["url"])]))

    # ---------------------------------------------------------------- transactions
    def operate(self, action, name, inf=None):
        if self.busy:
            theme.alert(self, "Another operation is running", "Please wait for it to finish.")
            return
        if action == "install":
            detail = (f"Download: {inf.get('Download Size', '?')} · Installed: {inf.get('Installed Size', '?')}.\n\n"
                      "Arch Linux does not support partial upgrades, so pending system updates are applied together with this install.")
            if proc.is_live():
                detail += "\n\nLive session: changes live in RAM and disappear on reboot."
            theme.confirm(self, f"Install {name}?", detail, "Install", lambda: self.start(pkg.install_cmd([name]), f"Installing {name}", name))
        elif action == "update":
            theme.confirm(self, f"Update {name}?", "This runs a full system upgrade (pacman -Syu), which is the supported way to update on Arch.",
                          "Update", lambda: self.start(pkg.install_cmd([name]), f"Updating {name}", name))
        else:
            theme.confirm(self, f"Remove {name}?", "Also removes dependencies that nothing else needs (pacman -Rns).",
                          "Remove", lambda: self.start(pkg.remove_cmd([name]), f"Removing {name}", name))

    def start(self, cmd, title, name):
        self.busy = True
        self.bottom.set_visible(True)
        self.op_label.set_text(title + "…")
        self.bar.set_fraction(0)
        self.log_view.get_buffer().set_text("$ " + " ".join(cmd[1:]) + "\n")
        self._pulse = GLib.timeout_add(120, lambda: (self.bar.pulse(), True)[1])
        proc.stream(cmd, self.on_line, lambda rc: self.on_done(rc, title, name))

    def on_line(self, line):
        buf = self.log_view.get_buffer()
        buf.insert(buf.get_end_iter(), line + "\n")
        m = pkg.PROGRESS_RE.match(line)
        if m:
            if self._pulse:
                GLib.source_remove(self._pulse)
                self._pulse = None
            i, n = int(m.group(1)), int(m.group(2))
            self.bar.set_fraction(i / max(n, 1))
            self.op_label.set_text(m.group(3))

    def on_done(self, rc, title, name):
        if self._pulse:
            GLib.source_remove(self._pulse)
            self._pulse = None
        self.busy = False
        if rc == 0:
            self.bar.set_fraction(1)
            self.op_label.set_text(f"{title}: done ✓")
        else:
            self.op_label.set_text(f"{title}: failed")
            buf = self.log_view.get_buffer()
            tail = "\n".join(buf.get_text(buf.get_start_iter(), buf.get_end_iter(), False).splitlines()[-12:])
            theme.alert(self, f"{title} failed", pkg.explain_rc(rc) or tail)
        if self.selected and self.selected["name"] == name:
            self.selected["installed"] = pkg.local_version(name) is not None
            self.on_select(None, self.results.get_selected_row())
        if self.mode == "installed":
            self.load_list()


class App(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="os.kocmoc.AppStore")

    def do_activate(self):
        if not self.get_active_window():
            theme.apply()
            StoreWindow(self)
        self.get_active_window().present()


if __name__ == "__main__":
    sys.exit(App().run(sys.argv))
