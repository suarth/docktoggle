# DockToggle

Windows-style Dock behavior for macOS: click the Dock icon of the app that's in front and its windows minimize; click again to bring them back. Adds a small menu-bar icon with Pause/Resume, and starts at login.

## Install

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/suarth/docktoggle/main/install.sh | bash
```

Then turn **DockToggle** on in **System Settings → Privacy & Security → Accessibility**, and run:

```bash
launchctl kickstart -k gui/$(id -u)/com.user.docktoggle
```

## Uninstall

```bash
launchctl unload -w ~/Library/LaunchAgents/com.user.docktoggle.plist
rm -rf ~/Applications/DockToggle.app ~/DockToggle ~/Library/LaunchAgents/com.user.docktoggle.plist
```
