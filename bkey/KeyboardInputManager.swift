import AppKit
import Observation

@Observable
final class KeyboardInputManager {
    private(set) var pressedKeyCodes: Set<UInt16> = []
    var onCharacterTyped: ((Character) -> Void)?

    private var localMonitor: Any?

    func startMonitoring() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            guard !event.isARepeat else { return }
            pressedKeyCodes.insert(event.keyCode)
            if let chars = event.characters, let char = chars.first {
                onCharacterTyped?(char)
            }
        case .keyUp:
            pressedKeyCodes.remove(event.keyCode)
        case .flagsChanged:
            updateModifierKey(event.keyCode, flags: event.modifierFlags)
        default:
            break
        }
    }

    private func updateModifierKey(_ keyCode: UInt16, flags: NSEvent.ModifierFlags) {
        // Modifier keyCodes: Shift(56,60), Ctrl(59,62), Opt(58,61), Cmd(55,54), Fn(63)
        let modifierKeyCodes: Set<UInt16> = [56, 60, 59, 62, 58, 61, 55, 54, 63]
        guard modifierKeyCodes.contains(keyCode) else { return }

        let isPressed: Bool
        switch keyCode {
        case 56, 60: isPressed = flags.contains(.shift)
        case 59, 62: isPressed = flags.contains(.control)
        case 58, 61: isPressed = flags.contains(.option)
        case 55, 54: isPressed = flags.contains(.command)
        case 63:     isPressed = flags.contains(.function)
        default:     isPressed = false
        }

        if isPressed {
            pressedKeyCodes.insert(keyCode)
        } else {
            pressedKeyCodes.remove(keyCode)
        }
    }
}
