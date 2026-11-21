import Carbon
import Foundation

struct Shortcut {
    let systemDomain: String
    let helperDomain: String
    let activate: () throws -> Void
    static let target = kVK_F18
    private let keys = "AppleSymbolicHotKeys", backup = "previousInputShortcutBackup"
    private static let fn = Int(CGEventFlags.maskSecondaryFn.rawValue)

    static let system = Shortcut(systemDomain: "com.apple.symbolichotkeys", helperDomain: "local.f19layer.helper") {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings")
        process.arguments = ["-u", "-virtualSession"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw failure("activateSettings exited with status \(process.terminationStatus)") }
    }

    private static func failure(_ message: String) -> NSError {
        NSError(domain: "F19Layer.Shortcut", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func sync(_ domain: String) throws {
        guard CFPreferencesAppSynchronize(domain as CFString) else { throw Self.failure("Could not synchronize \(domain)") }
    }

    private func read(_ key: String, _ domain: String) throws -> [String: Any]? {
        try sync(domain)
        guard let raw = CFPreferencesCopyAppValue(key as CFString, domain as CFString) else { return nil }
        guard let dictionary = raw as? [String: Any] else { throw Self.failure("Unexpected preference format: \(domain).\(key)") }
        return dictionary
    }

    private func write(_ value: [String: Any]?, _ key: String, _ domain: String) throws {
        CFPreferencesSetAppValue(key as CFString, value as CFDictionary?, domain as CFString)
        try sync(domain)
    }

    private func usesF18(_ raw: Any?, previous: Bool = false) -> Bool {
        guard let item = raw as? [String: Any], item["enabled"] as? Bool == true,
              let value = item["value"] as? [String: Any], let p = value["parameters"] as? [Int], p.count == 3 else { return false }
        return p[1] == Self.target && [0, Self.fn].contains(p[2]) && (!previous || (p[0] == 65535 && value["type"] as? String == "standard"))
    }

    func configure(restore: Bool) throws {
        var shortcuts = try read(keys, systemDomain) ?? [:]
        let saved = try read(backup, helperDomain)
        let managed = usesF18(shortcuts["60"], previous: true)
        if restore {
            guard let saved else { return }
            if managed {
                shortcuts["60"] = saved["original"]
                try write(shortcuts, keys, systemDomain)
            }
            try activate()
            try write(nil, backup, helperDomain)
            return
        }
        if let conflict = shortcuts.first(where: { $0.key != "60" && usesF18($0.value) }) {
            throw Self.failure("F18 is already assigned to system shortcut \(conflict.key); no shortcut was changed")
        }
        if !managed {
            // An empty dictionary records that shortcut 60 was originally absent.
            var snapshot: [String: Any] = [:]
            snapshot["original"] = shortcuts["60"]
            try write(snapshot, backup, helperDomain)
            shortcuts["60"] = ["enabled": true, "value": ["type": "standard", "parameters": [65535, Self.target, Self.fn]]]
            try write(shortcuts, keys, systemDomain)
        }
        // Retry activation even if an earlier process only completed the preference write.
        try activate()
    }
}
