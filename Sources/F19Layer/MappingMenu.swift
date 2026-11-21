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
        menu.addItem(withTitle: "Right Shift layer", action: nil, keyEquivalent: "").isEnabled = false
        for (label, direction) in Self.directions {
            let current = arrows.first { $0.value == direction }?.key
            let name = Self.keys.first { $0.1 == current }?.0
            let row = menu.addItem(withTitle: "\(label): \(name == " " ? "Space" : name ?? "Unassigned")", action: nil, keyEquivalent: "")
            let options = NSMenu()
            options.autoenablesItems = false
            for (keyName, key) in [("Unassigned", -1)] + Self.keys {
                let option = options.addItem(withTitle: keyName == " " ? "Space" : keyName, action: #selector(bind(_:)), keyEquivalent: "")
                option.target = self
                option.tag = key
                option.representedObject = direction
                option.state = key == (current ?? -1) ? .on : .off
                option.isEnabled = arrows[key] == nil || arrows[key] == direction
            }
            row.submenu = options
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit F19Layer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q").target = NSApp
    }

    @objc private func toggleCommand() {
        command.toggle()
        defaults.set(command, forKey: "useRightCommand")
        apply(arrows, command)
    }

    @objc private func bind(_ item: NSMenuItem) {
        guard let direction = item.representedObject as? Int else { return }
        arrows = arrows.filter { $0.value != direction }
        if item.tag >= 0 { arrows[item.tag] = direction }
        defaults.set(Dictionary(uniqueKeysWithValues: arrows.map { (String($0.key), $0.value) }), forKey: "arrowBindings")
        apply(arrows, command)
    }
}
