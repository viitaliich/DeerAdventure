import SwiftUI
import SpriteKit
import Combine

final class GenesisOverlayModel: ObservableObject {
    @Published var populationText: String = ""
    @Published var timerText: String = ""
    @Published var biomeTitle: String = ""
    @Published var gameOverText: String = ""
    @Published var isPlaying: Bool = false
    @Published var isGameOver: Bool = false
}

struct GenesisGameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var overlay = GenesisOverlayModel()

    @State private var scene: GenesisGameScene = {
        let scene = GenesisGameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }()

    @State private var joystickOffset: CGSize = .zero
    private let joystickRadius: CGFloat = 54
    private let joystickScreenOffset = CGSize(width: 70, height: -22)

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            VStack {
                topHUD
                Spacer()
                bottomHUD
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .statusBarHidden()
        .onAppear {
            scene.overlayModel = overlay
        }
    }

    private var topHUD: some View {
        HStack(spacing: 10) {
            Button {
                if overlay.isPlaying || overlay.isGameOver {
                    scene.returnToMenuFromOverlay()
                } else {
                    dismiss()
                }
            } label: {
                Label(overlay.isPlaying || overlay.isGameOver ? "Menu" : "Back", systemImage: "chevron.left")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            if overlay.isPlaying {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(overlay.populationText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(overlay.timerText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var bottomHUD: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220, alignment: .bottom)
            .overlay(alignment: .bottom) {
                if overlay.isPlaying && !overlay.isGameOver {
                    joystick
                        .offset(joystickScreenOffset)
                }
            }
            .overlay(alignment: .center) {
                if overlay.isGameOver {
                    let parts = overlay.gameOverText.split(separator: "\n", maxSplits: 1).map(String.init)
                    VStack(spacing: 10) {
                        Text(parts.first ?? "GAME OVER")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)

                        if parts.count > 1 {
                            Text(parts[1])
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                        }

                        Button("Return to Menu") {
                            scene.returnToMenuFromOverlay()
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
    }

    private var joystick: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: joystickRadius * 2, height: joystickRadius * 2)
                .overlay {
                    Circle().stroke(Color.white.opacity(0.55), lineWidth: 1.5)
                }

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: joystickRadius, height: joystickRadius)
                .overlay {
                    Circle().stroke(Color.white.opacity(0.8), lineWidth: 1)
                }
                .offset(joystickOffset)
        }
        .frame(width: joystickRadius * 2, height: joystickRadius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let length = max(0.0001, hypot(dx, dy))
                    let clamped = min(joystickRadius, length)
                    let nx = dx / length
                    let ny = dy / length

                    joystickOffset = CGSize(width: nx * clamped, height: ny * clamped)
                    scene.setInputVector(CGVector(dx: nx * clamped / joystickRadius, dy: -ny * clamped / joystickRadius))
                }
                .onEnded { _ in
                    joystickOffset = .zero
                    scene.setInputVector(.zero)
                }
        )
    }
}
