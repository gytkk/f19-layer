import Carbon
import XCTest
@testable import F19Layer

final class ShortcutTests: XCTestCase {
    let domain = "local.f19layer.tests." + UUID().uuidString
    var activations = 0
    var manager: Shortcut { Shortcut(systemDomain: domain, helperDomain: domain) { self.activations += 1 } }
    let key = "AppleSymbolicHotKeys" as CFString
    var keys: [String: Any] {
        get { CFPreferencesCopyAppValue(key, domain as CFString) as? [String: Any] ?? [:] }
        set { CFPreferencesSetAppValue(key, newValue as CFDictionary, domain as CFString) }
    }
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
    func binding(_ code: Int) -> [String: Any] {
        ["enabled": true, "value": ["type": "standard", "parameters": [65535, code, Int(CGEventFlags.maskSecondaryFn.rawValue)]]]
    }
    func testRepeatedLaunchAndRestore() throws {
        for initial in [["61": binding(kVK_F13)], ["60": binding(kVK_F13), "61": binding(kVK_F19)]] {
            keys = initial
            try manager.configure(restore: false)
            try manager.configure(restore: false)
            XCTAssertEqual(keys["60"] as? NSDictionary, binding(kVK_F18) as NSDictionary)
            try manager.configure(restore: true)
            XCTAssertEqual(keys as NSDictionary, initial as NSDictionary)
        }
        XCTAssertEqual(activations, 6)
    }
    func testRestorePreservesManualChange() throws {
        try manager.configure(restore: false)
        keys = ["60": binding(kVK_F19)]
        try manager.configure(restore: true)
        XCTAssertEqual(keys["60"] as? NSDictionary, binding(kVK_F19) as NSDictionary)
    }
    func testConflictDoesNotChangePreferences() {
        let initial = ["60": binding(kVK_F13), "61": binding(kVK_F18)]
        keys = initial
        XCTAssertThrowsError(try manager.configure(restore: false))
        XCTAssertEqual(keys as NSDictionary, initial as NSDictionary)
        XCTAssertEqual(activations, 0)
    }
}
