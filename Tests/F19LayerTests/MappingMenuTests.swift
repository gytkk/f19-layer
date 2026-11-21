import AppKit
import Carbon
import XCTest
@testable import F19Layer

final class MappingMenuTests: XCTestCase {
    func testEditThroughMenuAndReload() throws {
        _ = NSApplication.shared
        let suite = "local.f19layer.tests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var keys = Keyboard()
        let menu = MappingMenu(defaults: defaults) { keys.bindings = $0; keys.useRightCommand = $1 }
        let options = try XCTUnwrap(menu.menu.item(withTitle: "Left: ;")?.submenu)
        options.performActionForItem(at: options.indexOfItem(withTitle: "H"))
        XCTAssertEqual(keys.bindings[kVK_ANSI_H], kVK_LeftArrow)
        XCTAssertNil(keys.bindings[kVK_ANSI_Semicolon])
        menu.menu.performActionForItem(at: menu.menu.indexOfItem(withTitle: "Use Right Command to switch"))
        XCTAssertFalse(keys.useRightCommand)
        let reopened = MappingMenu(defaults: defaults) { XCTAssertEqual($0, keys.bindings); XCTAssertFalse($1) }
        XCTAssertNotNil(reopened.menu.item(withTitle: "Left: H"))
        XCTAssertEqual(reopened.menu.item(withTitle: "Quit F19Layer")?.action, #selector(NSApplication.terminate(_:)))
    }
}
