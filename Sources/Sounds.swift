import AVFoundation

/// 声音库：播放 .app 内 Resources 里的合成 WAV
final class SoundBank {
    enum Name: String, CaseIterable {
        case breakStart = "s_break_start"
        case caught = "s_caught"
        case sick = "s_sick"
        case bed = "s_bed"
        case ding = "s_ding"
        case hospital = "s_hospital"
    }

    private var players: [Name: AVAudioPlayer] = [:]
    var muted = false

    init() {
        for n in Name.allCases {
            if let url = Bundle.main.url(forResource: n.rawValue, withExtension: "wav"),
               let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                players[n] = p
            }
        }
    }

    func play(_ n: Name) {
        if muted { return }
        guard let p = players[n] else { return }
        p.currentTime = 0
        p.play()
    }
}
