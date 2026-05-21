import Carbon.HIToolbox
import Foundation

final class GlobalHotKeyManager {
    nonisolated(unsafe) private static var actions: [UInt32: () -> Void] = [:]
    nonisolated(unsafe) private static var nextID: UInt32 = 1

    private let id: UInt32
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(action: @escaping () -> Void) {
        self.id = Self.nextID
        Self.nextID += 1
        self.action = action
    }

    deinit {
        unregister()
    }

    func register() -> Bool {
        Self.actions[id] = action

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

        guard handlerStatus == noErr else {
            Self.actions[id] = nil
            return false
        }

        let hotKeyID = EventHotKeyID(signature: "QRNT".fourCharCode, id: id)
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_Q),
            modifiers,
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

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
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
