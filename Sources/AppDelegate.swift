import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingPanel: FloatingPanel!
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        setupMainMenu()
        setupFloatingPanel()
        setupStatusItem()
        setupHotkeys()
        
        NotificationCenter.default.addObserver(self, selector: #selector(closeSettings), name: Notification.Name("closeSettings"), object: nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        floatingPanel.orderFrontRegardless()
        return true
    }
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "О FloatNote", action: nil, keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        let settingsMenuItem = NSMenuItem(title: "Настройки...", action: #selector(openSettings), keyEquivalent: ",")
        settingsMenuItem.target = self
        appMenu.addItem(settingsMenuItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Завершить FloatNote", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        
        // Edit Menu (Enables Cmd+A, Cmd+C, Cmd+V, Cmd+X, Cmd+Z)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Правка")
        
        editMenu.addItem(withTitle: "Отменить", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Повторить", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Вырезать", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Скопировать", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Вставить", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Выбрать все", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        editMenuItem.submenu = editMenu
        NSApp.mainMenu = mainMenu
    }
    
    private func setupFloatingPanel() {
        let prefs = StorageManager.shared.preferences
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 800, height: 600)
        
        let initialWidth: CGFloat = CGFloat(max(prefs.windowWidth, 320))
        let initialHeight: CGFloat = CGFloat(max(prefs.windowHeight, 260))
        
        var frame: NSRect
        if let x = prefs.windowX, let y = prefs.windowY {
            let candidateFrame = NSRect(x: CGFloat(x), y: CGFloat(y), width: initialWidth, height: initialHeight)
            let isOnScreen = NSScreen.screens.contains { screen in
                screen.frame.intersects(candidateFrame)
            }
            if isOnScreen {
                frame = candidateFrame
            } else {
                let xPos = screenRect.maxX - initialWidth - 24
                let yPos = screenRect.maxY - initialHeight - 24
                frame = NSRect(x: xPos, y: yPos, width: initialWidth, height: initialHeight)
            }
        } else {
            // Position at top-right of main screen
            let xPos = screenRect.maxX - initialWidth - 24
            let yPos = screenRect.maxY - initialHeight - 24
            frame = NSRect(x: xPos, y: yPos, width: initialWidth, height: initialHeight)
        }
        
        floatingPanel = FloatingPanel(contentRect: frame)
        floatingPanel.contentView = FirstMouseHostingView(rootView: ContentView())
        floatingPanel.setClickThrough(prefs.isClickThrough)
        
        floatingPanel.orderFrontRegardless()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "FloatNote") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "📝"
            }
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        let prefs = StorageManager.shared.preferences
        
        let toggleTitle = floatingPanel.isVisible ? "Скрыть окно" : "Показать окно"
        let toggleItem = NSMenuItem(title: "\(toggleTitle) (\(prefs.toggleWindowHotkey.displayString))", action: #selector(toggleWindow), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let pinTitle = prefs.isPinned ? "Окно закреплено (Pin) ✓" : "Закрепить окно поверх всех (Pin)"
        let pinItem = NSMenuItem(title: pinTitle, action: #selector(togglePin), keyEquivalent: "")
        pinItem.target = self
        pinItem.state = prefs.isPinned ? .on : .off
        menu.addItem(pinItem)
        
        let ghostItem = NSMenuItem(title: "Сквозной клик (\(prefs.toggleGhostHotkey.displayString))", action: #selector(toggleGhost), keyEquivalent: "")
        ghostItem.target = self
        ghostItem.state = prefs.isClickThrough ? .on : .off
        menu.addItem(ghostItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let timerItem = NSMenuItem(title: "Таймер монтажа / Помодоро", action: #selector(toggleTimerWindow), keyEquivalent: "")
        timerItem.target = self
        menu.addItem(timerItem)
        
        let clipItem = NSMenuItem(title: "История буфера обмена", action: #selector(toggleClipboardWindow), keyEquivalent: "")
        clipItem.target = self
        menu.addItem(clipItem)
        
        let safeItem = NSMenuItem(title: "Безопасные зоны 9:16 (Reels/Shorts)", action: #selector(toggleSafeAreas), keyEquivalent: "")
        safeItem.target = self
        menu.addItem(safeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Настройки...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let resetPosItem = NSMenuItem(title: "Сбросить позицию окна", action: #selector(resetPosition), keyEquivalent: "")
        resetPosItem.target = self
        menu.addItem(resetPosItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Выход из FloatNote", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func toggleTimerWindow() {
        TimerPanelManager.shared.toggle()
    }
    
    @objc func toggleClipboardWindow() {
        ClipboardPanelManager.shared.toggle()
    }
    
    @objc func toggleSafeAreas() {
        SafeAreasManager.shared.toggle()
    }
    
    private func setupHotkeys() {
        HotkeyManager.shared.onToggleWindow = { [weak self] in
            self?.toggleWindow()
        }
        HotkeyManager.shared.onToggleGhost = { [weak self] in
            self?.toggleGhost()
        }
        
        HotkeyManager.shared.updateHotkeys(from: StorageManager.shared.preferences)
    }
    
    @objc func toggleWindow() {
        if floatingPanel.isVisible {
            floatingPanel.orderOut(nil)
        } else {
            floatingPanel.orderFrontRegardless()
            floatingPanel.makeKey()
        }
        updateMenu()
    }
    
    @objc func togglePin() {
        let current = StorageManager.shared.preferences.isPinned
        StorageManager.shared.preferences.isPinned = !current
        floatingPanel.setPinned(!current)
        updateMenu()
    }
    
    @objc func toggleGhost() {
        let current = StorageManager.shared.preferences.isClickThrough
        StorageManager.shared.preferences.isClickThrough = !current
        floatingPanel.setClickThrough(!current)
        updateMenu()
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
                styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.minSize = NSSize(width: 420, height: 450)
            panel.title = "Настройки FloatNote"
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.level = NSWindow.Level(rawValue: 1003)
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.isReleasedWhenClosed = false
            settingsWindow = panel
        }
        
        // Re-create hosting controller so SettingsView picks up latest state every time it is opened
        settingsWindow?.contentViewController = NSHostingController(rootView: SettingsView())
        settingsWindow?.level = NSWindow.Level(rawValue: 1003)
        settingsWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        settingsWindow?.center()
        settingsWindow?.orderFrontRegardless()
        settingsWindow?.makeKey()
    }
    
    @objc func closeSettings() {
        settingsWindow?.close()
    }
    
    @objc func resetPosition() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 800, height: 600)
        let initialWidth: CGFloat = 380
        let initialHeight: CGFloat = 480
        let xPos = screenRect.maxX - initialWidth - 24
        let yPos = screenRect.maxY - initialHeight - 24
        let defaultFrame = NSRect(x: xPos, y: yPos, width: initialWidth, height: initialHeight)
        floatingPanel.setFrame(defaultFrame, display: true, animate: true)
        
        StorageManager.shared.preferences.windowX = Double(defaultFrame.origin.x)
        StorageManager.shared.preferences.windowY = Double(defaultFrame.origin.y)
        StorageManager.shared.preferences.windowWidth = Double(defaultFrame.size.width)
        StorageManager.shared.preferences.windowHeight = Double(defaultFrame.size.height)
        
        floatingPanel.orderFrontRegardless()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Instant First Click Support
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

