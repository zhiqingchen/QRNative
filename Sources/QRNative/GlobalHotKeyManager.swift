import Carbon.HIToolbox
import Foundation

final class GlobalHotKeyManager {
    nonisolated(unsafe) private static var actions: [UInt32: () -> Void] = [:]
    nonisolated(unsafe) private static var nextID: UInt32 = 1
    nonisolated(unsafe) private static var eventHandlerRef: EventHandlerRef?

    private let id: UInt32
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?

    init(action: @escaping () -> Void) {
        self.id = Self.nextID
        Self.nextID += 1
        self.action = action
    }

    deinit {
        unregister()
    }

    func register(shortcut: GlobalShortcut) -> Bool {
        Self.actions[id] = action

        guard Self.installEventHandlerIfNeeded() else {
            Self.actions[id] = nil
            return false
        }

        let hotKeyID = EventHotKeyID(signature: "QRNT".fourCharCode, id: id)
        let registerStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            unregister()
            return false
        }

        return true
    }

    private static func installEventHandlerIfNeeded() -> Bool {
        guard eventHandlerRef == nil else {
            return true
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return status
                }

                if let action = GlobalHotKeyManager.actions[hotKeyID.id] {
                    DispatchQueue.main.async {
                        action()
                    }
                }

                return noErr
            },
            1,
            &eventSpec,
            nil,
            &eventHandlerRef
        )

        return handlerStatus == noErr
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        Self.actions[id] = nil
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        unicodeScalars.reduce(0) { result, scalar in
            (result << 8) + FourCharCode(scalar.value)
        }
    }
}
