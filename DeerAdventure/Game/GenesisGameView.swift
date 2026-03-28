import SwiftUI
import SpriteKit
import SwiftData

struct GenesisGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var dayEntries: [DayValueEntry]
    @StateObject private var overlay = GenesisOverlayModel()

    @State private var scene: GenesisGameScene = {
        let scene = GenesisGameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }()

    @State private var joystickOffset: CGSize = .zero
    @State private var pauseDetailsVisible: Bool = false
    @State private var isResumingFromPause: Bool = false
    private let pauseMorphDuration: TimeInterval = 0.5
    private let pauseDetailsMorphDuration: TimeInterval = 0.24
    private let modalEdgeInset: CGFloat = 66
    private let gameplayEdgeInset: CGFloat = 16
    private let joystickRadius: CGFloat = 54
    private let joystickScreenOffset = CGSize(width: 70, height: -22)

    private func triggerButtonHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

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

            morphingStatusCard
            stateModal
        }
        .statusBarHidden()
        .animation(.smooth(duration: pauseMorphDuration), value: overlay.isPaused)
        .onAppear {
            scene.overlayModel = overlay
            applyTodayBreedingMultiplier()
        }
        .onChange(of: overlay.isPaused) { _, isPaused in
            if isPaused {
                isResumingFromPause = false
                pauseDetailsVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseMorphDuration + 0.02) {
                    if overlay.isPaused {
                        withAnimation(.easeInOut(duration: pauseDetailsMorphDuration)) {
                            pauseDetailsVisible = true
                        }
                    }
                }
            } else {
                pauseDetailsVisible = false
                isResumingFromPause = false
            }
        }
        .onChange(of: dayEntries) { _, _ in
            applyTodayBreedingMultiplier()
        }
    }

    private func applyTodayBreedingMultiplier() {
        let todayKey = DayValueKey.make(from: Date())
        let todayValue = dayEntries
            .filter { $0.dateKey == todayKey }
            .map { $0.value }
            .max() ?? 0

        scene.setBreedingBirthMultiplier(todayValue)
    }

    private var topHUD: some View {
        Group {
            if overlay.isGameOver {
                EmptyView()
            } else {
                HStack(spacing: 10) {
                    Button {
                        triggerButtonHaptic()
                        if overlay.isPlaying {
                            scene.pauseGameFromOverlay()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Group {
                            if overlay.isPlaying {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.black)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .scaleEffect(overlay.isPaused ? 0.001 : 1.0)
                                    .animation(.easeInOut(duration: 0.34), value: overlay.isPaused)
                            } else {
                                Label("Back", systemImage: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 14)
                                    .frame(height: 44)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, overlay.isPlaying ? 12 : 0)

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var morphingStatusCard: some View {
        if overlay.isPlaying && !overlay.isGameOver {
            GeometryReader { _ in
                let gameplayCardWidth: CGFloat = 210

                VStack(spacing: 10) {
                    if overlay.isPaused {
                        Text(overlay.pauseText)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .scaleEffect(pauseDetailsVisible ? 1.0 : 0.001)
                            .opacity(pauseDetailsVisible ? 1.0 : 0.0)

                        Text(overlay.topScoreText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .scaleEffect(pauseDetailsVisible ? 1.0 : 0.001)
                            .opacity(pauseDetailsVisible ? 1.0 : 0.0)
                    }

                    HStack(spacing: 10) {
                        Text(overlay.breedingMultiplierText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(
                                width: overlay.isPaused ? 0 : 44,
                                height: overlay.isPaused ? 0 : 44
                            )
                            .background(.ultraThinMaterial, in: Circle())
                            .scaleEffect(overlay.isPaused ? 0.001 : 1.0)

                        VStack(alignment: overlay.isPaused ? .center : .trailing, spacing: overlay.isPaused ? 8 : 4) {
                            Text(overlay.populationText)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .multilineTextAlignment(overlay.isPaused ? .center : .trailing)

                            Text(overlay.timerText)
                                .font(
                                    .system(
                                        size: 20,
                                        weight: overlay.isPaused ? .bold : .semibold,
                                        design: .rounded
                                    )
                                )
                                .monospacedDigit()
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.snappy(duration: 0.32), value: overlay.timerText)
                                .multilineTextAlignment(overlay.isPaused ? .center : .trailing)
                        }
                        .frame(maxWidth: .infinity, alignment: overlay.isPaused ? .center : .trailing)
                    }

                    if overlay.isPaused {
                        HStack(spacing: 10) {
                            Button("Continue") {
                                triggerButtonHaptic()
                                guard !isResumingFromPause else { return }
                                isResumingFromPause = true
                                withAnimation(.easeInOut(duration: pauseDetailsMorphDuration)) {
                                    pauseDetailsVisible = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + pauseDetailsMorphDuration + 0.02) {
                                    scene.resumeGameFromOverlay()
                                }
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(.ultraThinMaterial, in: Capsule())

                            Button("Exit") {
                                triggerButtonHaptic()
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                        .scaleEffect(pauseDetailsVisible ? 1.0 : 0.001)
                        .opacity(pauseDetailsVisible ? 1.0 : 0.0)
                        .allowsHitTesting(pauseDetailsVisible)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .frame(width: overlay.isPaused ? nil : gameplayCardWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: overlay.isPaused ? .bottom : .topTrailing)
                .padding(.horizontal, overlay.isPaused ? modalEdgeInset : gameplayEdgeInset)
                .padding(.bottom, overlay.isPaused ? modalEdgeInset : 0)
                .padding(.top, overlay.isPaused ? 0 : 12)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var bottomHUD: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220, alignment: .bottom)
            .overlay(alignment: .bottom) {
                if overlay.isPlaying && !overlay.isGameOver {
                    joystick
                        .scaleEffect(overlay.isPaused ? 0.001 : 1.0)
                        .opacity(overlay.isPaused ? 0.0 : 1.0)
                        .allowsHitTesting(!overlay.isPaused)
                        .animation(.easeInOut(duration: 0.34), value: overlay.isPaused)
                        .offset(joystickScreenOffset)
                }
            }
    }

    @ViewBuilder
    private var stateModal: some View {
        if overlay.isGameOver {
            let parts = overlay.gameOverText.split(separator: "\n", maxSplits: 1).map(String.init)
            VStack(spacing: 10) {
                Text(parts.first ?? "GAME OVER")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text(overlay.topScoreText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    if parts.count > 1 {
                        Text(parts[1])
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 10) {
                    Button("Restart") {
                        triggerButtonHaptic()
                        scene.restartGameFromOverlay()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.ultraThinMaterial, in: Capsule())

                    Button("Exit") {
                        triggerButtonHaptic()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, modalEdgeInset)
            .padding(.bottom, modalEdgeInset)
            .ignoresSafeArea(edges: .bottom)
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
