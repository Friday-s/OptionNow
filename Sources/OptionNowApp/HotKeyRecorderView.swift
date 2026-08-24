import AppKit
import Carbon
import SwiftUI

struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var configuration: HotKeyConfiguration

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.configuration = configuration
        view.onRecord = { configuration = $0 }
        return view
    }

    func updateNSView(_ view: RecorderView, context: Context) {
        view.configuration = configuration
        view.needsDisplay = true
    }
}

final class RecorderView: NSView {
    var configuration = HotKeyConfiguration.defaultValue
    var onRecord: ((HotKeyConfiguration) -> Void)?
    private var isRecording = false

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 150, height: 30) }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        var modifiers: UInt32 = 0
        if event.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if event.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }

        guard modifiers != 0 else {
            NSSound.beep()
            return
        }
        let recorded = HotKeyConfiguration(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        configuration = recorded
        onRecord?(recorded)
        isRecording = false
        window?.makeFirstResponder(nil)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        // Same tokens as the SwiftUI controls next to it: chip radius, hairline
        // stroke, accent wash while recording.
        let bounds = self.bounds.insetBy(dx: DS.Stroke.hairline, dy: DS.Stroke.hairline)
        let path = NSBezierPath(
            roundedRect: bounds,
            xRadius: DS.Radius.chip,
            yRadius: DS.Radius.chip
        )
        (isRecording ? NSColor(DS.Color.accentSoft) : NSColor(DS.Color.card)).setFill()
        path.fill()
        NSColor(isRecording ? DS.Color.accent : DS.Color.strokeStrong).setStroke()
        path.lineWidth = DS.Stroke.border
        path.stroke()

        let text = isRecording ? "请按新的快捷键" : configuration.displayName
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2),
            withAttributes: attributes
        )
    }
}
