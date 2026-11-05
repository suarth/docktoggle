import Cocoa
let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
_ = AXIsProcessTrustedWithOptions(opts)
var enabled = true
var pending: NSRunningApplication? = nil
var tap: CFMachPort? = nil
func windows(_ app: NSRunningApplication) -> [AXUIElement] {
    let ax = AXUIElementCreateApplication(app.processIdentifier)
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(ax, kAXWindowsAttribute as CFString, &v) == .success,
          let wins = v as? [AXUIElement] else { return [] }
    return wins
}
func isStandard(_ w: AXUIElement) -> Bool {
    var sr: CFTypeRef?
    AXUIElementCopyAttributeValue(w, kAXSubroleAttribute as CFString, &sr)
    return (sr as? String) == (kAXStandardWindowSubrole as String)
}
func isMinimized(_ w: AXUIElement) -> Bool {
    var m: CFTypeRef?
    AXUIElementCopyAttributeValue(w, kAXMinimizedAttribute as CFString, &m)
    return (m as? Bool) ?? false
}
func hasOpenWindow(_ app: NSRunningApplication) -> Bool {
    if app.isHidden { return false }
    return windows(app).contains { isStandard($0) && !isMinimized($0) }
}
func minimizeAll(_ app: NSRunningApplication) {
    for w in windows(app) where isStandard(w) && !isMinimized(w) {
        AXUIElementSetAttributeValue(w, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }
}
func dockItemURL(at p: CGPoint) -> URL? {
    var el: AXUIElement?
    guard AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(p.x), Float(p.y), &el) == .success, let e = el else { return nil }
    var pid: pid_t = 0
    AXUIElementGetPid(e, &pid)
    guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first, dock.processIdentifier == pid else { return nil }
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(e, kAXURLAttribute as CFString, &v) == .success, let u = v, CFGetTypeID(u) == CFURLGetTypeID() else { return nil }
    return (u as! CFURL) as URL
}
let cb: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
    } else if type == .leftMouseDown {
        pending = nil
        if enabled, let url = dockItemURL(at: event.location), let front = NSWorkspace.shared.frontmostApplication,
           front.bundleURL?.standardizedFileURL == url.standardizedFileURL, hasOpenWindow(front) { pending = front }
    } else if type == .leftMouseUp, let app = pending {
        pending = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { minimizeAll(app) }
    }
    return Unmanaged.passUnretained(event)
}
class Controller: NSObject {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let toggleItem = NSMenuItem(title: "Pause", action: #selector(toggle), keyEquivalent: "")
    override init() {
        super.init()
        toggleItem.target = self
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "DockToggle", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(toggleItem)
        item.menu = menu
        update()
    }
    @objc func toggle() { enabled.toggle(); update() }
    func update() {
        let name = enabled ? "dock.arrow.down.rectangle" : "pause.rectangle"
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: "DockToggle") {
            img.isTemplate = true
            item.button?.image = img
        } else {
            item.button?.title = enabled ? "▼" : "॥"
        }
        toggleItem.title = enabled ? "Pause" : "Resume"
    }
}
let mask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)
tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: CGEventMask(mask), callback: cb, userInfo: nil)
guard let t = tap else { sleep(5); exit(1) }
CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, t, 0), .commonModes)
CGEvent.tapEnable(tap: t, enable: true)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = Controller()
app.run()
