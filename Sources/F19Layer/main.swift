import ApplicationServices
import AppKit

func configureShortcut(restore: Bool) {
    do { try Shortcut.system.configure(restore: restore) }
    catch {
        fputs("F19Layer shortcut setup: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

if CommandLine.arguments.dropFirst().elementsEqual(["--restore-shortcut"]) {
    configureShortcut(restore: true)
    exit(0)
}
if !AXIsProcessTrusted() {
    fputs("F19Layer needs Accessibility access. Grant access to the app and relaunch it.\n", stderr)
    exit(1)
}
var keyboard = Keyboard()
let types: [CGEventType] = [.flagsChanged, .keyDown, .keyUp]
let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
var tap: CFMachPort?
tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                        eventsOfInterest: mask, callback: { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        keyboard.held.removeAll()
        keyboard.targetDown = false
        keyboard.rightCommandDown = false
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    guard let output = keyboard.handle(type, event, post: { $0.post(tap: .cghidEventTap) })
    else { return nil }
    return Unmanaged.passUnretained(output)
}, userInfo: nil)
guard let port = tap, let source = CFMachPortCreateRunLoopSource(nil, port, 0) else {
    fputs("Cannot create the keyboard event tap in this login session.\n", stderr)
    exit(1)
}
configureShortcut(restore: false)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: port, enable: true)
let application = NSApplication.shared
application.setActivationPolicy(.accessory)
let inputStatusItem = InputStatusItem()
let mappings = MappingMenu { bindings, command in
    keyboard.bindings = bindings
    keyboard.useRightCommand = command
    keyboard.rightCommandDown = false
}
inputStatusItem.item.menu = mappings.menu
withExtendedLifetime((inputStatusItem, mappings)) { application.run() }
