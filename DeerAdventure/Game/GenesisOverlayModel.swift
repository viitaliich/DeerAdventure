import Combine

final class GenesisOverlayModel: ObservableObject {
    @Published var populationText: String = ""
    @Published var timerText: String = ""
    @Published var breedingMultiplierText: String = "x1"
    @Published var topScoreText: String = "Top Score: 0"
    @Published var biomeTitle: String = ""
    @Published var gameOverText: String = ""
    @Published var pauseText: String = "PAUSE"
    @Published var isPlaying: Bool = false
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false
}
