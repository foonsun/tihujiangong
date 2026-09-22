import AppKit
import SwiftUI

// MARK: - 非激活浮动面板

final class PelicanPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - 控制器

final class PanelController: NSObject, NSApplicationDelegate {
    static let cardSize = NSSize(width: 236, height: 262)
    static let stripHeight: CGFloat = 170

    let state = GameState()
    let sounds = SoundBank()
    let idleTracker = IdleTracker()

    private(set) var panel: PelicanPanel!
    private var statsWindow: NSWindow?
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var lastSave = Date.distantPast
    private var lastCardOrigin: NSPoint = .zero
    private var isStrip = false

    private var hpMenuItem: NSMenuItem!
    private var hospitalMenuItem: NSMenuItem!
    private var muteMenuItem: NSMenuItem!
    private var hideMenuItem: NSMenuItem!
    private var loginMenuItem: NSMenuItem!

    // MARK: 生命周期

    func applicationDidFinishLaunching(_ note: Notification) {
        // 单实例
        if let selfApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.foonsun.pelican-nanny")
            .first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            _ = selfApp
            NSApp.terminate(nil)
            return
        }

        setupStatusItem()
        setupPanel()
        loadState()
        sounds.muted = state.muted
        state.loginItemEnabled = FileManager.default.fileExists(atPath: Self.launchAgentPath)

        if CommandLine.arguments.contains("--shots") {
            savePoseShots()
        }
        startTimer()
    }

    func applicationWillTerminate(_ note: Notification) {
        saveState()
    }

    // MARK: 面板

    private func setupPanel() {
        let scr = NSScreen.main ?? NSScreen.screens[0]
        let vf = scr.visibleFrame
        let size = Self.cardSize
        let origin = NSPoint(x: vf.maxX - size.width - 16, y: vf.maxY - size.height - 10)

        let p = PelicanPanel(contentRect: NSRect(origin: origin, size: size),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        p.level = .screenSaver
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        p.becomesKeyOnlyIfNeeded = true
        p.isFloatingPanel = true
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        let host = NSHostingView(rootView: PanelRootView(state: state, controller: self))
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        p.orderFrontRegardless()
        panel = p
        lastCardOrigin = origin
        state.windowOriginX = Double(origin.x)

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMove),
                                               name: NSWindow.didMoveNotification, object: p)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize),
                                               name: NSWindow.didResizeNotification, object: p)
    }

    @objc private func windowDidMove() {
        if !isStrip { lastCardOrigin = panel.frame.origin }
        state.windowOriginX = Double(panel.frame.minX)
    }

    @objc private func windowDidResize() {
        state.windowOriginX = Double(panel.frame.minX)
    }

    private func keepPanelOnScreen() {
        guard !isStrip else { return }
        let f = panel.frame
        let scr = panel.screen ?? NSScreen.main
        guard let scr else { return }
        let vf = scr.visibleFrame
        if f.maxX < vf.minX + 40 || f.minX > vf.maxX - 40 ||
           f.maxY < vf.minY + 40 || f.minY > vf.maxY - 40 {
            // 回收到当前屏幕右上角
            panel.setFrameOrigin(NSPoint(x: vf.maxX - f.size.width - 12,
                                         y: vf.maxY - f.size.height - 12))
        }
    }

    // MARK: 走屏动画

    private func expandStrip() {
        guard !isStrip else { return }
        isStrip = true
        panel.ignoresMouseEvents = true   // 走屏期间点击穿透
        let scr = panel.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let target = NSRect(x: scr.frame.minX, y: scr.frame.maxY - Self.stripHeight,
                            width: scr.frame.width, height: Self.stripHeight)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(target, display: true)
        }
    }

    private func restoreCard() {
        guard isStrip else { return }
        isStrip = false
        panel.ignoresMouseEvents = false
        let origin = lastCardOrigin
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(NSRect(origin: origin, size: Self.cardSize), display: true)
        }
    }

    // MARK: 动作（按钮 + 菜单共用）

    func startBreak() {
        guard !state.inBreak else { return }
        sounds.play(.breakStart)
        state.walkFromScreenX = panel.frame.minX + 118
        state.startBreak()
        expandStrip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 1.5) { [weak self] in
            guard let self else { return }
            self.restoreCard()
            self.state.finishWalkOut(now: Date())
        }
    }

    private func beginWalkBack(happy: Bool) {
        state.walkFromScreenX = panel.frame.minX + 118
        state.beginWalkIn(now: Date(), happy: happy)
        expandStrip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 1.5) { [weak self] in
            guard let self else { return }
            self.restoreCard()
            self.state.finishWalkIn(now: Date(), happy: happy)
        }
    }

    @objc func openStats() {
        if statsWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
                             styleMask: [.titled, .closable],
                             backing: .buffered, defer: false)
            w.title = "鹈鹕监工 · 统计"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: StatsView(state: state))
            w.center()
            statsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        statsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func doHospital() {
        guard state.freeHospitalization(now: Date()) else { return }
        sounds.play(.hospital)
        saveState()
    }

    @objc func toggleMute() {
        state.muted.toggle()
        sounds.muted = state.muted
        saveState()
    }

    @objc func togglePanel() {
        if state.panelVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
        state.panelVisible.toggle()
        updateMenu()
    }

    // MARK: 菜单栏

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🦩"
        let menu = NSMenu()
        hpMenuItem = NSMenuItem(title: "HP", action: nil, keyEquivalent: "")
        hpMenuItem.isEnabled = false
        menu.addItem(hpMenuItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "📊 打开统计", action: #selector(openStats), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🚶 起来休息", action: #selector(startBreakMenu), keyEquivalent: ""))
        hospitalMenuItem = NSMenuItem(title: "🏥 免费住院（今日）", action: #selector(doHospital), keyEquivalent: "")
        menu.addItem(hospitalMenuItem)
        muteMenuItem = NSMenuItem(title: "🔊 声音：开", action: #selector(toggleMute), keyEquivalent: "")
        menu.addItem(muteMenuItem)
        hideMenuItem = NSMenuItem(title: "🪟 隐藏小窗", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(hideMenuItem)
        loginMenuItem = NSMenuItem(title: "🚀 开机自启：关", action: #selector(toggleLogin), keyEquivalent: "")
        menu.addItem(loginMenuItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "📸 保存姿势截图（调试）", action: #selector(savePoseShots), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 鹈鹕监工", action: #selector(quit), keyEquivalent: ""))
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    @objc func startBreakMenu() { startBreak() }
    @objc func quit() { NSApp.terminate(nil) }

    private func updateMenu() {
        let s = state
        var t = "HP \(Int(s.hp.rounded())) · \(s.hpState.label)"
        if s.inBreak {
            t += " · 休息中"
        } else if s.away {
            t += " · 离开中"
        } else {
            t += " · 已坐 \(Int(s.consecutiveSittingMinutes)) 分" + (s.deepSitting ? " ⚠️×2" : "")
        }
        if hpMenuItem.title != t { hpMenuItem.title = t }

        hospitalMenuItem.isEnabled = !s.hospitalizedToday && !s.inBreak
        let ht = s.hospitalizedToday ? "🏥 今日住院已用" : "🏥 免费住院（今日）"
        if hospitalMenuItem.title != ht { hospitalMenuItem.title = ht }

        let mt = s.muted ? "🔇 声音：关" : "🔊 声音：开"
        if muteMenuItem.title != mt { muteMenuItem.title = mt }

        let hdt = s.panelVisible ? "🪟 隐藏小窗" : "🪟 显示小窗"
        if hideMenuItem.title != hdt { hideMenuItem.title = hdt }

        let lt = s.loginItemEnabled ? "🚀 开机自启：开" : "🚀 开机自启：关"
        if loginMenuItem.title != lt { loginMenuItem.title = lt }
    }

    // MARK: 主循环

    private func startTimer() {
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let now = Date()
        let idle = idleTracker.seconds()
        let events = state.tick(now: now, idle: idle)
        for e in events { handleEvent(e) }
        sounds.muted = state.muted
        keepPanelOnScreen()
        updateMenu()
        if Date().timeIntervalSince(lastSave) > 5 { saveState() }
    }

    private func handleEvent(_ e: GameEvent) {
        switch e {
        case .entered(let s):
            switch s {
            case .sick: sounds.play(.sick)
            case .bedridden: sounds.play(.bed)
            default: break
            }
        case .breakGenuine:
            sounds.play(.ding)
            beginWalkBack(happy: true)
        case .breakCaught:
            sounds.play(.caught)
            beginWalkBack(happy: false)
        }
    }

    // MARK: 持久化

    static var stateURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PelicanNanny", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("state.json")
    }

    private func saveState() {
        let origin: [Double] = isStrip
            ? [Double(lastCardOrigin.x), Double(lastCardOrigin.y)]
            : [Double(panel.frame.minX), Double(panel.frame.minY)]
        let snap = state.snapshot(origin: origin)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: Self.stateURL, options: Data.WritingOptions.atomic)
            lastSave = Date()
        }
    }

    private func loadState() {
        guard let data = try? Data(contentsOf: Self.stateURL),
              let snap = try? JSONDecoder().decode(GameState.Snapshot.self, from: data) else { return }
        state.restore(snap)
        if snap.panelOrigin.count == 2 {
            let pt = NSPoint(x: snap.panelOrigin[0], y: snap.panelOrigin[1])
            if NSScreen.screens.contains(where: { $0.frame.insetBy(dx: -100, dy: -100).contains(pt) }) {
                let vf = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
                let x = min(max(pt.x, vf.minX + 8), vf.maxX - Self.cardSize.width - 8)
                let y = min(max(pt.y, vf.minY + 8), vf.maxY - Self.cardSize.height - 8)
                panel.setFrameOrigin(NSPoint(x: x, y: y))
                lastCardOrigin = NSPoint(x: x, y: y)
                state.windowOriginX = x
            }
        }
    }

    // MARK: 开机自启（LaunchAgent）

    static var launchAgentPath: String {
        ("~/Library/LaunchAgents/com.foonsun.pelican-nanny.plist" as NSString).expandingTildeInPath
    }

    @objc func toggleLogin() {
        let path = Self.launchAgentPath
        let fm = FileManager.default
        if fm.fileExists(atPath: path) {
            runLaunchctl(["unload", path])
            try? fm.removeItem(atPath: path)
            state.loginItemEnabled = false
        } else {
            let bin = Bundle.main.bundlePath + "/Contents/MacOS/PelicanNanny"
            let xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>Label</key><string>com.foonsun.pelican-nanny</string>
              <key>ProgramArguments</key><array><string>\(bin)</string></array>
              <key>RunAtLoad</key><true/>
              <key>KeepAlive</key><false/>
            </dict>
            </plist>
            """
            try? xml.write(toFile: path, atomically: true, encoding: .utf8)
            runLaunchctl(["load", "-w", path])
            state.loginItemEnabled = true
        }
        updateMenu()
    }

    private func runLaunchctl(_ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
    }

    // MARK: 调试：离屏渲染各姿势 PNG

    @objc func savePoseShots() {
        let dir = URL(fileURLWithPath: "/tmp/pelican-shots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let now = Date().timeIntervalSinceReferenceDate
        let poses: [(String, PelicanDraw)] = [
            ("energetic", PelicanDraw(hpState: .energetic, mood: .none, pose: .standing)),
            ("normal", PelicanDraw(hpState: .normal, mood: .none, pose: .standing)),
            ("wilted", PelicanDraw(hpState: .wilted, mood: .none, pose: .standing)),
            ("sick", PelicanDraw(hpState: .sick, mood: .none, pose: .standing,
                                 symptoms: [.thermometer, .dizzy])),
            ("sick-bandage", PelicanDraw(hpState: .sick, mood: .none, pose: .standing,
                                         symptoms: [.bandage, .cough])),
            ("bedridden", PelicanDraw(hpState: .bedridden, mood: .none, pose: .standing)),
            ("angry", PelicanDraw(hpState: .normal, mood: .angry, pose: .standing)),
            ("happy", PelicanDraw(hpState: .normal, mood: .happy, pose: .standing)),
            ("hospital", PelicanDraw(hpState: .energetic, mood: .happy, pose: .standing, showBandage: true)),
            ("resting", PelicanDraw(hpState: .normal, mood: .none, pose: .resting)),
            ("walking", PelicanDraw(hpState: .normal, mood: .none, pose: .walkingOut,
                                    walkT0: now, walkFromX: 118)),
            ("away", PelicanDraw(hpState: .normal, mood: .none, pose: .standing, away: true))
        ]
        for (name, d) in poses {
            let host = NSHostingView(rootView: PelicanView(draw: d)
                .frame(width: 220, height: 150))
            host.frame = NSRect(x: 0, y: 0, width: 220, height: 150)
            host.layoutSubtreeIfNeeded()
            guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { continue }
            host.cacheDisplay(in: host.bounds, to: rep)
            if let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: dir.appendingPathComponent(name + ".png"))
            }
        }
        NSWorkspace.shared.open(dir)
    }
}
