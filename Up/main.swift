import Cocoa
import IOKit.pwr_mgt
import ServiceManagement

// MARK: - Launch at Login

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var sleepAssertionID: IOPMAssertionID = 0
    private var isActive = false
    private var timer: Timer?
    private var activationTime: Date?
    private var selectedDuration: TimeInterval = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else { return }
        button.image = makeIcon(active: false)
        button.image?.isTemplate = true
        button.toolTip = "Up! – Click to prevent sleep"
        button.action = #selector(statusBarButtonClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func makeIcon(active: Bool) -> NSImage {
        let text = active ? "Up!" : "Up"
        let font = NSFont.systemFont(ofSize: 13, weight: active ? .bold : .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let size = attrStr.size()
        let imageSize = NSSize(width: ceil(size.width) + 2, height: 18)
        let image = NSImage(size: imageSize, flipped: false) { rect in
            let drawPoint = NSPoint(x: 1, y: (rect.height - size.height) / 2)
            attrStr.draw(at: drawPoint)
            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            toggleSleep()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let stateTitle = isActive ? "Active – Preventing Sleep" : "Inactive"
        let stateItem = NSMenuItem(title: stateTitle, action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        if isActive, let activationTime = activationTime {
            let elapsed = Date().timeIntervalSince(activationTime)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .abbreviated
            if let str = formatter.string(from: elapsed) {
                let timeItem = NSMenuItem(title: "Active for \(str)", action: nil, keyEquivalent: "")
                timeItem.isEnabled = false
                menu.addItem(timeItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let toggleTitle = isActive ? "Deactivate" : "Activate Indefinitely"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleSleep), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let durations: [(String, TimeInterval)] = [
            ("15 Minutes", 15 * 60),
            ("30 Minutes", 30 * 60),
            ("1 Hour", 3600),
            ("2 Hours", 7200),
            ("4 Hours", 14400),
        ]

        for (title, duration) in durations {
            let item = NSMenuItem(title: "Activate for \(title)", action: #selector(setDuration(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = duration
            if isActive && selectedDuration == duration {
                item.state = .on
            }
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit Up!", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleSleep() {
        if isActive {
            deactivate()
        } else {
            activate(duration: 0)
        }
    }

    @objc private func setDuration(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? TimeInterval else { return }
        if isActive { deactivate() }
        activate(duration: duration)
    }

    private func activate(duration: TimeInterval) {
        let reason = "Up! is preventing sleep" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &sleepAssertionID
        )

        guard result == kIOReturnSuccess else {
            print("Failed to create power assertion: \(result)")
            return
        }

        isActive = true
        selectedDuration = duration
        activationTime = Date()
        updateIcon()

        timer?.invalidate()
        timer = nil
        if duration > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.deactivate()
            }
        }
    }

    private func deactivate() {
        if sleepAssertionID != 0 {
            IOPMAssertionRelease(sleepAssertionID)
            sleepAssertionID = 0
        }

        isActive = false
        activationTime = nil
        selectedDuration = 0
        timer?.invalidate()
        timer = nil
        updateIcon()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        button.image = makeIcon(active: isActive)
        button.image?.isTemplate = true
        button.toolTip = isActive ? "Up! – Sleep prevented" : "Up! – Click to prevent sleep"
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        LaunchAtLogin.toggle()
    }

    @objc private func quit() {
        deactivate()
        NSApp.terminate(nil)
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
