import AppKit
import Carbon

final class MappingMenu: NSObject, NSMenuDelegate {
    private static let keys = Array(zip(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[];'/-=, .`\\").map(String.init), [
        kVK_ANSI_A,kVK_ANSI_B,kVK_ANSI_C,kVK_ANSI_D,kVK_ANSI_E,kVK_ANSI_F,kVK_ANSI_G,kVK_ANSI_H,kVK_ANSI_I,kVK_ANSI_J,kVK_ANSI_K,kVK_ANSI_L,kVK_ANSI_M,kVK_ANSI_N,kVK_ANSI_O,kVK_ANSI_P,kVK_ANSI_Q,kVK_ANSI_R,kVK_ANSI_S,kVK_ANSI_T,kVK_ANSI_U,kVK_ANSI_V,kVK_ANSI_W,kVK_ANSI_X,kVK_ANSI_Y,kVK_ANSI_Z,kVK_ANSI_0,kVK_ANSI_1,kVK_ANSI_2,kVK_ANSI_3,kVK_ANSI_4,kVK_ANSI_5,kVK_ANSI_6,kVK_ANSI_7,kVK_ANSI_8,kVK_ANSI_9,kVK_ANSI_LeftBracket,kVK_ANSI_RightBracket,kVK_ANSI_Semicolon,kVK_ANSI_Quote,kVK_ANSI_Slash,kVK_ANSI_Minus,kVK_ANSI_Equal,kVK_ANSI_Comma,kVK_Space,kVK_ANSI_Period,kVK_ANSI_Grave,kVK_ANSI_Backslash]))
    private static let directions = [("Up", kVK_UpArrow), ("Left", kVK_LeftArrow), ("Right", kVK_RightArrow), ("Down", kVK_DownArrow)]
    let menu = NSMenu()
    let defaults: UserDefaults
    let apply: ([Int: Int], Bool) -> Void
    private var arrows = Keyboard.arrows
    private var command = true
    private var configWindow: NSWindow?
    private var pickers: [NSPopUpButton] = []

    init(defaults: UserDefaults = .standard, apply: @escaping ([Int: Int], Bool) -> Void) {
        self.defaults = defaults
        self.apply = apply
        super.init()
        if let stored = defaults.dictionary(forKey: "arrowBindings") as? [String: Int] {
            arrows = [:]
            for (_, key) in Self.keys {
                if let arrow = stored[String(key)], Self.directions.contains(where: { $0.1 == arrow }), !arrows.values.contains(arrow) { arrows[key] = arrow }
            }
        }
        command = defaults.object(forKey: "useRightCommand") as? Bool ?? true
        apply(arrows, command)
        menu.autoenablesItems = false
        menu.delegate = self
        rebuild()
    }

    func menuNeedsUpdate(_ menu: NSMenu) { rebuild() }

    private func rebuild() {
        menu.removeAllItems()
        menu.addItem(withTitle: "Input source switch: F18", action: nil, keyEquivalent: "").isEnabled = false
        let toggle = menu.addItem(withTitle: "Use Right Command to switch", action: #selector(toggleCommand), keyEquivalent: "")
        toggle.target = self
        toggle.state = command ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Layer config", action: #selector(openConfig), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit F19Layer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q").target = NSApp
    }

    @objc private func toggleCommand() {
        command.toggle()
        defaults.set(command, forKey: "useRightCommand")
        apply(arrows, command)
    }

    @objc private func openConfig() {
        if configWindow == nil {
            let grid = NSGridView()
            grid.rowSpacing = 8
            grid.columnSpacing = 16
            for (label, direction) in Self.directions {
                let picker = NSPopUpButton()
                picker.tag = direction
                picker.target = self
                picker.action = #selector(bind(_:))
                picker.autoenablesItems = false
                picker.setAccessibilityLabel("Right Shift key for " + label)
                for (name, key) in [("Unassigned", -1)] + Self.keys {
                    picker.addItem(withTitle: name == " " ? "Space" : name)
                    picker.lastItem?.tag = key
                }
                grid.addRow(with: [NSTextField(labelWithString: label), picker])
                pickers.append(picker)
            }
            let hint = NSTextField(labelWithString: "Choose the key to hold with Right Shift for each arrow.")
            let content = NSStackView(views: [hint, grid])
            content.orientation = .vertical
            content.alignment = .leading
            content.spacing = 18
            content.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: content.fittingSize),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.contentView = content
            window.title = "Layer config"
            window.isReleasedWhenClosed = false
            window.center()
            configWindow = window
        }
        refreshPickers()
        NSApp.activate(ignoringOtherApps: true)
        configWindow?.makeKeyAndOrderFront(nil)
    }

    private func refreshPickers() {
        for picker in pickers {
            for item in picker.itemArray {
                item.isEnabled = arrows[item.tag] == nil || arrows[item.tag] == picker.tag
            }
            picker.selectItem(withTag: arrows.first { $0.value == picker.tag }?.key ?? -1)
        }
    }

    @objc private func bind(_ picker: NSPopUpButton) {
        guard let item = picker.selectedItem, item.isEnabled else { return }
        let direction = picker.tag
        arrows = arrows.filter { $0.value != direction }
        if item.tag >= 0 { arrows[item.tag] = direction }
        refreshPickers()
        defaults.set(Dictionary(uniqueKeysWithValues: arrows.map { (String($0.key), $0.value) }), forKey: "arrowBindings")
        apply(arrows, command)
    }
}
