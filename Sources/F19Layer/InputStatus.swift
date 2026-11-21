import AppKit
import Carbon

struct InputStatus {
    let language: String?
    let name: String?

    var glyph: String {
        switch language?.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first {
        case "ko": return "가"
        case "en": return "A"
        default: return "·"
        }
    }

    static func current() -> Self {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return Self(language: nil, name: nil)
        }
        func property(_ key: CFString) -> AnyObject? {
            TISGetInputSourceProperty(source, key).map { Unmanaged<AnyObject>.fromOpaque($0).takeUnretainedValue() }
        }
        let languages = property(kTISPropertyInputSourceLanguages) as? [String]
        return Self(language: languages?.first, name: property(kTISPropertyLocalizedName) as? String)
    }
}

final class InputStatusItem {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let center: NotificationCenter
    private var observer: NSObjectProtocol?

    init(center: NotificationCenter = DistributedNotificationCenter.default(), current: @escaping () -> InputStatus = InputStatus.current) {
        self.center = center
        let refresh = { [weak self] in
            let status = current()
            let description = "F19Layer: " + (status.name ?? "Unknown input source")
            self?.item.button?.title = status.glyph
            self?.item.button?.toolTip = description
            self?.item.button?.setAccessibilityLabel(description)
        }
        observer = center.addObserver(
            forName: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil,
            queue: .main, using: { _ in refresh() })
        refresh()
    }

    deinit {
        if let observer { center.removeObserver(observer) }
        NSStatusBar.system.removeStatusItem(item)
    }
}
