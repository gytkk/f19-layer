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
        XCTAssertNil(menu.menu.item(withTitle: "Left: ;"))
        let index = menu.menu.indexOfItem(withTitle: "Layer config")
        XCTAssertGreaterThanOrEqual(index, 0)
        menu.menu.performActionForItem(at: index)
        let window = try XCTUnwrap(NSApp.windows.first { $0.title == "Layer config" && $0.isVisible })
        defer { window.close() }
        let grid = try XCTUnwrap((window.contentView as? NSStackView)?.arrangedSubviews.last as? NSGridView)
        let options = try XCTUnwrap(grid.cell(atColumnIndex: 1, rowIndex: 1).contentView as? NSPopUpButton)
        XCTAssertEqual(options.selectedItem?.title, ";")
        options.selectItem(withTitle: "H")
        XCTAssertTrue(options.sendAction(options.action, to: options.target))
        window.close()
        menu.menu.performActionForItem(at: index)
        XCTAssertTrue(window.isVisible)
        XCTAssertEqual(keys.bindings[kVK_ANSI_H], kVK_LeftArrow)
        XCTAssertNil(keys.bindings[kVK_ANSI_Semicolon])
        menu.menu.performActionForItem(at: menu.menu.indexOfItem(withTitle: "Use Right Command to switch"))
        XCTAssertFalse(keys.useRightCommand)
        let reopened = MappingMenu(defaults: defaults) { XCTAssertEqual($0, keys.bindings); XCTAssertFalse($1) }
        XCTAssertNotNil(reopened.menu.item(withTitle: "Layer config"))
        XCTAssertEqual(reopened.menu.item(withTitle: "Quit F19Layer")?.action, #selector(NSApplication.terminate(_:)))
    }
}
