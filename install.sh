#!/bin/bash
# DockToggle installer: click a frontmost app's Dock icon to minimize it (Windows-style).
set -e
APP="$HOME/Applications/DockToggle.app"
PLIST="$HOME/Library/LaunchAgents/com.user.docktoggle.plist"
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Command line developer tools are needed. Click Install in the pop-up, then run this installer again."
  xcode-select --install || true
  exit 1
fi
mkdir -p "$HOME/DockToggle" "$APP/Contents/MacOS" "$HOME/Library/LaunchAgents"
echo "Downloading source..."
curl -fsSL https://raw.githubusercontent.com/suarth/docktoggle/main/main.swift -o "$HOME/DockToggle/main.swift"
cat > "$APP/Contents/Info.plist" <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.user.docktoggle</string>
<key>CFBundleName</key><string>DockToggle</string>
<key>CFBundleExecutable</key><string>DockToggle</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
PL
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.user.docktoggle</string>
<key>ProgramArguments</key><array><string>$APP/Contents/MacOS/DockToggle</string></array>
<key>RunAtLoad</key><true/><key>KeepAlive</key><true/><key>ThrottleInterval</key><integer>10</integer>
</dict></plist>
PL
echo "Building..."
swiftc -O "$HOME/DockToggle/main.swift" -o "$APP/Contents/MacOS/DockToggle"
codesign --force --deep -s - "$APP"
tccutil reset Accessibility com.user.docktoggle >/dev/null 2>&1 || true
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load -w "$PLIST"
echo ""
echo "DockToggle installed."
echo "Next: when asked, click 'Open System Settings' and turn DockToggle ON under Accessibility."
echo "Then run:  launchctl kickstart -k gui/\$(id -u)/com.user.docktoggle"
