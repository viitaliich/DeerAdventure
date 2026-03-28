import AVFoundation

final class SoundManager {
    private var loopingPlayers: [String: AVAudioPlayer] = [:]

    func playLoop(_ name: String) {
        stopAllLoops()
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.55
            player.prepareToPlay()
            player.play()
            loopingPlayers[name] = player
        } catch {
            print("[Sound] loop error for \(name): \(error)")
        }
    }

    func playOneShot(_ name: String, volume: Float = 0.9) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = volume
            player.prepareToPlay()
            player.play()
            // Держим временно в словаре, чтобы не деаллоцировался до окончания.
            let key = "oneshot_\(name)_\(Date().timeIntervalSince1970)"
            loopingPlayers[key] = player
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) { [weak self] in
                self?.loopingPlayers.removeValue(forKey: key)
            }
        } catch {
            print("[Sound] one-shot error for \(name): \(error)")
        }
    }

    func stopAllLoops() {
        for (_, player) in loopingPlayers {
            if player.numberOfLoops != 0 {
                player.stop()
            }
        }
        loopingPlayers = loopingPlayers.filter { $0.value.numberOfLoops == 0 }
    }

    func stopAll() {
        for (_, player) in loopingPlayers { player.stop() }
        loopingPlayers.removeAll()
    }
}
