import Carbon
import CoreGraphics

struct Keyboard {
    // NX_DEVICELSHIFTKEYMASK and NX_DEVICERSHIFTKEYMASK in IOLLEvent.h.
    static let left: UInt64 = 2, right: UInt64 = 4
    // NX_DEVICELCMDKEYMASK and NX_DEVICERCMDKEYMASK in IOLLEvent.h.
    static let leftCommand: UInt64 = 0x08, rightCommand: UInt64 = 0x10
    static let marker: Int64 = 0x4631394C415952
    static let arrows = [kVK_ANSI_LeftBracket: kVK_UpArrow, kVK_ANSI_Semicolon: kVK_LeftArrow,
                         kVK_ANSI_Quote: kVK_RightArrow, kVK_ANSI_Slash: kVK_DownArrow]
    var bindings = Self.arrows
    var useRightCommand = true
    var held: [Int: Int] = [:]
    var targetDown = false
    var rightCommandDown = false

    private func postSwitch(from down: CGEvent, post: (CGEvent) -> Void) -> Bool {
        guard let up = down.copy() else { return false }
        up.type = .keyUp
        for pulse in [down, up] {
            pulse.flags = down.flags.intersection([.maskSecondaryFn, .maskNumericPad, .maskAlphaShift])
            pulse.setIntegerValueField(.eventSourceUserData, value: Self.marker)
            post(pulse)
        }
        return true
    }

    mutating func handle(_ type: CGEventType, _ event: CGEvent, post: (CGEvent) -> Void) -> CGEvent? {
        if event.getIntegerValueField(.eventSourceUserData) == Self.marker { return event }
        let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let repeated = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let commandPressed = event.flags.rawValue & Self.rightCommand != 0
        if useRightCommand && type == .flagsChanged && code == kVK_RightCommand {
            if !commandPressed {
                rightCommandDown = false
            } else if !rightCommandDown {
                guard let down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(Shortcut.target), keyDown: true) else { return event }
                down.flags = event.flags.intersection(.maskAlphaShift).union(.maskSecondaryFn)
                guard postSwitch(from: down, post: post) else { return event }
                rightCommandDown = true
            }
            return nil
        }
        if useRightCommand && commandPressed {
            var flags = event.flags.rawValue & ~Self.rightCommand
            if flags & Self.leftCommand == 0 { flags &= ~CGEventFlags.maskCommand.rawValue }
            event.flags = CGEventFlags(rawValue: flags)
        }
        let right = event.flags.rawValue & Self.right != 0
        if right {
            var flags = event.flags.rawValue & ~Self.right
            if flags & Self.left == 0 { flags &= ~CGEventFlags.maskShift.rawValue }
            event.flags = CGEventFlags(rawValue: flags)
        }
        if type == .flagsChanged { return code == kVK_RightShift ? nil : event }
        if code == Shortcut.target {
            if type == .keyUp {
                defer { targetDown = false }
                return targetDown ? nil : event
            }
            if targetDown { return nil }
            guard !repeated, let down = event.copy(), postSwitch(from: down, post: post) else { return event }
            targetDown = true
            return nil
        }
        // Latch the decision at key-down, including pass-through presses.
        if type == .keyDown && !repeated {
            if right, let arrow = bindings[code] { held[code] = arrow }
            else { held.removeValue(forKey: code) }
        }
        guard let arrow = held[code] else { return event }
        if type == .keyUp { held.removeValue(forKey: code) }
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(arrow))
        event.flags.insert(.maskNumericPad)
        return event
    }
}
