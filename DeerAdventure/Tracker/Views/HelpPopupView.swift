import SwiftUI

struct HelpPopupView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("""
Welcome to Deer Adventure!

This app combines an activity tracker with a mini-game. Here's a quick guide to get you started.

1) Main Screen
• The Today button opens the current week.
• The Play button launches the game scene.
• The ? button opens this help window.

2) Working with Weeks and Days
• Inside a week, you can increase and decrease daily values using the + and − buttons.
• The daily goal is 10 deer.

3) The Game
• Use the joystick to move.
• Keep an eye on the timer, multiplier, and top score.
• Multiplier is based on your current dayly progress — the more deer you have for the day, the higher it goes!
• You can pause the game at any time using the top controls.

Tip:
Fill in the values regularly — it's easier to see your progress across weeks and months, and the game becomes a fun bonus to your routine.
""")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
