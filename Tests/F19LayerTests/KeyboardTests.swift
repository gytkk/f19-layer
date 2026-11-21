import XCTest
import Carbon
import CoreGraphics
@testable import F19Layer

final class KeyboardTests: XCTestCase {
    var keyboard = Keyboard()
    var pulses: [CGEvent] = []
    func send(_ key: Int, _ type: CGEventType, _ flags: UInt64 = 0, repeated: Bool = false) -> CGEvent? {
        let e = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: type != .keyUp)!
        e.type = type
        e.flags = CGEventFlags(rawValue: flags)
        e.setIntegerValueField(.keyboardEventAutorepeat, value: repeated ? 1 : 0)
        return keyboard.handle(type, e) { self.pulses.append($0) }
    }
    let right = CGEventFlags.maskShift.rawValue | Keyboard.right
    func testArrowLifetime() {
        for (key, arrow) in [(kVK_ANSI_LeftBracket,kVK_UpArrow),(kVK_ANSI_Semicolon,kVK_LeftArrow),(kVK_ANSI_Quote,kVK_RightArrow),(kVK_ANSI_Slash,kVK_DownArrow)] {
            for event in [send(key,.keyDown,right), send(key,.keyDown,repeated:true), send(key,.keyUp)] {
                XCTAssertEqual(event?.getIntegerValueField(.keyboardEventKeycode), Int64(arrow))
                XCTAssertEqual(event?.flags.contains(.maskShift), false)
            }
            XCTAssertEqual(send(key,.keyDown)?.getIntegerValueField(.keyboardEventKeycode),Int64(key))
            XCTAssertEqual(send(key,.keyUp,right)?.getIntegerValueField(.keyboardEventKeycode),Int64(key))
        }
    }
    func testShiftOwnership() {
        XCTAssertNil(send(kVK_RightShift,.flagsChanged,right))
        XCTAssertEqual(send(kVK_ANSI_A,.keyDown,right)?.flags.rawValue,0)
        XCTAssertEqual(send(kVK_ANSI_A,.keyDown,right | Keyboard.left)?.flags.rawValue, CGEventFlags.maskShift.rawValue | Keyboard.left)
        XCTAssertNil(send(kVK_RightShift,.flagsChanged))
    }
    func testRightCommandSwitchesOnPressAndRearmsOnRelease() {
        let right = Keyboard.rightCommand | CGEventFlags.maskCommand.rawValue
        let both = right | Keyboard.leftCommand
        XCTAssertNil(send(kVK_RightCommand, .flagsChanged, right))
        XCTAssertEqual(pulses.map(\.type), [.keyDown, .keyUp])
        for pulse in pulses {
            XCTAssertEqual(pulse.getIntegerValueField(.keyboardEventKeycode), Int64(kVK_F18))
            XCTAssertFalse(pulse.flags.contains(.maskCommand))
            XCTAssertNotNil(keyboard.handle(pulse.type, pulse) { _ in XCTFail("Recursive switch") })
        }
        XCTAssertNil(send(kVK_RightCommand, .flagsChanged, right))
        XCTAssertEqual(send(kVK_ANSI_A, .keyDown, right)?.flags.rawValue, 0)
        let left = Keyboard.leftCommand | CGEventFlags.maskCommand.rawValue
        XCTAssertEqual(send(kVK_Command, .flagsChanged, both)?.flags.rawValue, left)
        XCTAssertEqual(send(kVK_ANSI_A, .keyUp, both)?.flags.rawValue, left)
        XCTAssertNil(send(kVK_RightCommand, .flagsChanged, left))
        XCTAssertEqual(pulses.count, 2)
        XCTAssertNil(send(kVK_RightCommand, .flagsChanged, both))
        XCTAssertEqual(pulses.count, 4)
    }
    func testF18FiresBeforeReleaseOnlyOnce() {
        XCTAssertNil(send(kVK_F18,.keyDown,right))
        XCTAssertEqual(pulses.map(\.type), [.keyDown,.keyUp])
        for p in pulses { XCTAssertNotNil(keyboard.handle(p.type,p) { _ in XCTFail("Recursive pulse") }) }
        XCTAssertNil(send(kVK_F18,.keyDown,repeated:true))
        XCTAssertNil(send(kVK_F18,.keyUp))
        XCTAssertEqual(pulses.count,2)
        XCTAssertNil(send(kVK_F18,.keyDown))
        XCTAssertEqual(pulses.count,4)
    }
}
