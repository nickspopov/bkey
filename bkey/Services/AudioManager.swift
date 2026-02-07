import AppKit

struct AudioManager {
    private static let keystrokeSound = NSSound(named: "Tink")
    private static let errorSound = NSSound(named: "Basso")

    static func playKeystroke() { keystrokeSound?.stop(); keystrokeSound?.play() }
    static func playError() { errorSound?.stop(); errorSound?.play() }
}
