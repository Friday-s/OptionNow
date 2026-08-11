import Carbon
import Foundation

@MainActor
final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var activeConfiguration: HotKeyConfiguration?
    private let onPressed: () -> Void
    private let onReleased: () -> Void

    init(onPressed: @escaping () -> Void, onReleased: @escaping () -> Void) {
        self.onPressed = onPressed
        self.onReleased = onReleased

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                let kind = GetEventKind(event)
                Task { @MainActor in
                    if kind == UInt32(kEventHotKeyPressed) {
                        manager.onPressed()
                    } else if kind == UInt32(kEventHotKeyReleased) {
                        manager.onReleased()
                    }
                }
                return noErr
            },
            eventTypes.count,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    @discardableResult
    func register(_ configuration: HotKeyConfiguration) -> Bool {
        let previous = activeConfiguration
        unregisterCurrent()
        if registerRaw(configuration) {
            activeConfiguration = configuration
            return true
        }
        if let previous, registerRaw(previous) {
            activeConfiguration = previous
        }
        return false
    }

    private func registerRaw(_ configuration: HotKeyConfiguration) -> Bool {
        let signature = OSType(0x4F_50_54_4E) // OPTN
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        return RegisterEventHotKey(
            configuration.keyCode,
            configuration.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        ) == noErr
    }

    private func unregisterCurrent() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
