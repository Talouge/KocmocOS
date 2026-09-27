#!/usr/bin/env python3
"""(Re)start swaybg with the wallpaper chosen in Kocmoc Settings."""
import os, subprocess, sys
sys.path.insert(0, "/usr/lib/kocmoc")
from kocmoc import config
s = config.load()
path = s["appearance"]["wallpaper"]
if not os.path.exists(path):
    path = config.DEFAULTS["appearance"]["wallpaper"]
subprocess.run(["pkill", "-x", "swaybg"], check=False)
if os.path.exists(path):
    subprocess.Popen(["swaybg", "-m", "fill", "-i", path], start_new_session=True)
else:
    subprocess.Popen(["swaybg", "-c", "#0b0b0b"], start_new_session=True)
