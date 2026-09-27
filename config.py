<?xml version="1.0" encoding="UTF-8"?>
<!-- Kocmoc OS window manager defaults. Rendered per user into
     ~/.cache/kocmoc/labwc/rc.xml by kocmoc-labwc-gen (user settings applied). -->
<labwc_config>
  <core>
    <decoration>server</decoration>
    <gap>6</gap>
  </core>
  <theme>
    <name>Kocmoc</name>
    <icon>Papirus-Dark</icon>
    <cornerRadius>10</cornerRadius>
    <dropShadows>yes</dropShadows>
    <font place="ActiveWindow"><name>Inter</name><size>10</size><weight>bold</weight></font>
    <font place="InactiveWindow"><name>Inter</name><size>10</size><weight>normal</weight></font>
    <font place="MenuItem"><name>Inter</name><size>10</size></font>
    <font place="OnScreenDisplay"><name>Inter</name><size>11</size></font>
  </theme>
  <placement><policy>center</policy></placement>
  <desktops number="4">
    <popupTime>700</popupTime>
    <prefix>Desktop</prefix>
  </desktops>
  <snapping>
    <range>12</range>
    <topMaximize>yes</topMaximize>
  </snapping>
  <keyboard>
    <default />
    <repeatRate>25</repeatRate>
    <repeatDelay>600</repeatDelay>
    <keybind key="Super_L" onRelease="yes"><action name="Execute" command="fuzzel" /></keybind>
    <keybind key="W-d"><action name="Execute" command="fuzzel" /></keybind>
    <keybind key="W-Return"><action name="Execute" command="foot" /></keybind>
    <keybind key="W-e"><action name="Execute" command="thunar" /></keybind>
    <keybind key="W-i"><action name="Execute" command="kocmoc-settings" /></keybind>
    <keybind key="W-a"><action name="Execute" command="kocmoc-quick" /></keybind>
    <keybind key="W-l"><action name="Execute" command="kocmoc-lock" /></keybind>
    <keybind key="W-q"><action name="Close" /></keybind>
    <keybind key="W-Up"><action name="ToggleMaximize" /></keybind>
    <keybind key="W-Down"><action name="Iconify" /></keybind>
    <keybind key="W-Left"><action name="SnapToEdge" direction="left" /></keybind>
    <keybind key="W-Right"><action name="SnapToEdge" direction="right" /></keybind>
    <keybind key="W-1"><action name="GoToDesktop" to="1" /></keybind>
    <keybind key="W-2"><action name="GoToDesktop" to="2" /></keybind>
    <keybind key="W-3"><action name="GoToDesktop" to="3" /></keybind>
    <keybind key="W-4"><action name="GoToDesktop" to="4" /></keybind>
    <keybind key="W-S-1"><action name="SendToDesktop" to="1" follow="no" /></keybind>
    <keybind key="W-S-2"><action name="SendToDesktop" to="2" follow="no" /></keybind>
    <keybind key="W-S-3"><action name="SendToDesktop" to="3" follow="no" /></keybind>
    <keybind key="W-S-4"><action name="SendToDesktop" to="4" follow="no" /></keybind>
    <keybind key="C-W-Left"><action name="GoToDesktop" to="left" wrap="yes" /></keybind>
    <keybind key="C-W-Right"><action name="GoToDesktop" to="right" wrap="yes" /></keybind>
    <keybind key="Print"><action name="Execute" command="sh -c 'mkdir -p ~/Pictures &amp;&amp; f=~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png &amp;&amp; grim &quot;$f&quot; &amp;&amp; notify-send -a Kocmoc Screenshot &quot;Saved to $f&quot;'" /></keybind>
    <keybind key="S-Print"><action name="Execute" command="sh -c 'mkdir -p ~/Pictures &amp;&amp; f=~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png &amp;&amp; grim -g &quot;$(slurp)&quot; &quot;$f&quot; &amp;&amp; notify-send -a Kocmoc Screenshot &quot;Saved to $f&quot;'" /></keybind>
    <keybind key="XF86AudioRaiseVolume"><action name="Execute" command="wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+" /></keybind>
    <keybind key="XF86AudioLowerVolume"><action name="Execute" command="wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" /></keybind>
    <keybind key="XF86AudioMute"><action name="Execute" command="wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" /></keybind>
    <keybind key="XF86MonBrightnessUp"><action name="Execute" command="brightnessctl -c backlight set 5%+" /></keybind>
    <keybind key="XF86MonBrightnessDown"><action name="Execute" command="brightnessctl -c backlight set 5%-" /></keybind>
  </keyboard>
  <mouse>
    <default />
  </mouse>
  <libinput>
    <device category="default">
      <pointerSpeed>0</pointerSpeed>
      <naturalScroll>no</naturalScroll>
      <leftHanded>no</leftHanded>
    </device>
    <device category="touchpad">
      <pointerSpeed>0</pointerSpeed>
      <naturalScroll>yes</naturalScroll>
      <tap>yes</tap>
      <disableWhileTyping>yes</disableWhileTyping>
    </device>
  </libinput>
</labwc_config>
