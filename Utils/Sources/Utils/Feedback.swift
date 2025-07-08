import SwiftUI
import AudioToolbox
import CoreHaptics
import AVFoundation

@MainActor
public struct Feedback
{
    public var soundsEnabled: Bool = false
    public var hapticsEnabled: Bool = false

    public init(sounds: Bool = false, haptics: Bool = false) {
        self.soundsEnabled = sounds
        self.hapticsEnabled = haptics
    }
    
    public func triggerTapSound() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
            AudioServicesPlaySystemSound(1104)
        } catch {
            print("Error setting audio session: \(error)")
        }
    }
    
    public func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public func trigger() {
        if (self.soundsEnabled) {
            self.triggerTapSound()
        }
        if (self.hapticsEnabled) {
            self.triggerHaptic()
        }
    }
}
