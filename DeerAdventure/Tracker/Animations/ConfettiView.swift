import SwiftUI
import ConfettiSwiftUI

struct ConfettiView: View {
    let trigger: Int
    var onFinished: (() -> Void)? = nil

    var body: some View {
        Group {
            switch ConfettiConfig.style {
            case .custom:
                ConfettiCelebrationView(trigger: trigger)
            case .simibac:
                SimibacWrapper(trigger: trigger)
            case .kirchberg:
                KirchbergConfettiWrapper(trigger: trigger)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: trigger) {
            try? await Task.sleep(for: .seconds(ConfettiConfig.style.animationDuration))
            guard !Task.isCancelled else { return }
            onFinished?()
        }
    }
}

// MARK: - ConfettiSwiftUI wrapper

private struct SimibacWrapper: View {
    let trigger: Int
    @State private var internalTrigger: Int = 0

    var body: some View {
        Color.clear
            .confettiCannon(
                trigger: $internalTrigger,
                num: 40,
                confettis: [.shape(.slimRectangle), .shape(.circle), .shape(.square)],
                colors: [.red, .pink, .yellow, .teal, .blue, .green],
                confettiSize: 8,
                rainHeight: 600,
                openingAngle: .degrees(60),
                closingAngle: .degrees(120),
                radius: 350
            )
            .onAppear {
                internalTrigger += 1
            }
            .onChange(of: trigger) { _, _ in
                internalTrigger += 1
            }
    }
}

// MARK: - Kirchberg configuration

private extension ConfettiConfiguration {
    static let bouquet: ConfettiConfiguration = {
        var c = ConfettiConfiguration()
        c.particleCount = 120
        c.spread = 1.2               // ~70°
        c.gravity = 2000
        c.startVelocity = 900
        c.gravityAnimationDuration = 1.5
        c.birthRateAnimationDuration = 0.3
        c.scale = 0.15
        c.scaleRange = 0.1
        c.lifetime = ConfettiConfig.kirchbergLifetime
        return c
    }()
}

// MARK: - Kirchberg wrapper

private struct KirchbergConfettiWrapper: UIViewRepresentable {
    let trigger: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> KirchbergConfettiView {
        KirchbergConfettiView(
            emitters: [
                .shape(.rectangle, color: .systemRed),
                .shape(.rectangle, color: .systemYellow),
                .shape(.circle, color: .systemPink),
                .shape(.circle, color: .systemBlue),
                .shape(.circle, color: .systemGreen)
            ],
            direction: .bottom,
            animation: .default,
            configuration: .bouquet
        )
    }

    func updateUIView(_ uiView: KirchbergConfettiView, context: Context) {
        guard context.coordinator.lastTrigger != trigger else { return }
        context.coordinator.lastTrigger = trigger
        DispatchQueue.main.async {
            uiView.emit()
        }
    }

    class Coordinator {
        var lastTrigger: Int = -1
    }
}
