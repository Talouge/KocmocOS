<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu>
  <!-- Desktop context menu (right click on the wallpaper) -->
  <menu id="root-menu" label="Kocmoc">
    <item label="Applications"><action name="Execute" command="fuzzel" /></item>
    <item label="Terminal"><action name="Execute" command="foot" /></item>
    <item label="Files"><action name="Execute" command="thunar" /></item>
    <separator />
    <item label="Change wallpaper"><action name="Execute" command="kocmoc-settings --page appearance" /></item>
    <item label="Display settings"><action name="Execute" command="kocmoc-settings --page display" /></item>
    <item label="Settings"><action name="Execute" command="kocmoc-settings" /></item>
    <separator />
    <menu id="desktops" label="Desktops">
      <item label="Desktop 1"><action name="GoToDesktop" to="1" /></item>
      <item label="Desktop 2"><action name="GoToDesktop" to="2" /></item>
      <item label="Desktop 3"><action name="GoToDesktop" to="3" /></item>
      <item label="Desktop 4"><action name="GoToDesktop" to="4" /></item>
    </menu>
    <separator />
    <item label="Lock"><action name="Execute" command="kocmoc-lock" /></item>
    <item label="Log out"><action name="Exit" /></item>
  </menu>
  <!-- Window menu (titlebar icon / right click on titlebar) -->
  <menu id="client-menu">
    <item label="Minimize"><action name="Iconify" /></item>
    <item label="Maximize"><action name="ToggleMaximize" /></item>
    <item label="Move"><action name="Move" /></item>
    <item label="Resize"><action name="Resize" /></item>
    <item label="Always on top"><action name="ToggleAlwaysOnTop" /></item>
    <menu id="client-send-to" label="Move to desktop">
      <item label="Desktop 1"><action name="SendToDesktop" to="1" /></item>
      <item label="Desktop 2"><action name="SendToDesktop" to="2" /></item>
      <item label="Desktop 3"><action name="SendToDesktop" to="3" /></item>
      <item label="Desktop 4"><action name="SendToDesktop" to="4" /></item>
    </menu>
    <separator />
    <item label="Close"><action name="Close" /></item>
  </menu>
</openbox_menu>
