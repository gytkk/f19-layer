import AppKit
import Carbon
import XCTest
@testable import F19Layer

final class InputStatusTests: XCTestCase {
    func testLanguageLabels() {
        for (lang, glyph) in [("ko-KR", "가"), ("en", "A"), ("ja", "·"), (nil, "·")] {
            XCTAssertEqual(InputStatus(language: lang, name: nil).glyph, glyph)
        }
    }

    func testSourceChangeUpdatesButtonWithoutAKeyPress() throws {
        _ = NSApplication.shared
        let center = NotificationCenter()
        var source = InputStatus(language: "en", name: "ABC")
        let indicator = InputStatusItem(center: center) { source }
        let button = try XCTUnwrap(indicator.item.button)
        XCTAssertEqual(button.title, "A")
        source = InputStatus(language: "ko", name: "2-Set Korean")
        center.post(name: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil)
        XCTAssertEqual(button.title, "가")
        XCTAssertEqual(button.toolTip, "F19Layer: 2-Set Korean")
    }

    func testStatusButtonShowsSelectedSource() throws {
        _ = NSApplication.shared
        let status = InputStatus.current()
        let indicator = InputStatusItem()
        let button = try XCTUnwrap(indicator.item.button)
        XCTAssertEqual(button.title, status.glyph)
        XCTAssertNotNil(status.name)
        XCTAssertEqual(button.toolTip, "F19Layer: " + (status.name ?? ""))
    }
}
