#if DEBUG
import SwiftUI
import OSLog

struct HabitProgressItem: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var unit: String
    var goal: Double
    var step: Double
    var accentColor: Color
    var backgroundColor: Color
    var current: Double
}

struct HabitTileDemoView: View {
    @State private var items: [HabitProgressItem] = [
        HabitProgressItem(title: "Drink Water", subtitle: "Hydration", icon: "💧", unit: "ml", goal: 3000, step: 250, accentColor: Color(hex: "#28A6FF"), backgroundColor: Color(hex: "#DFF1FF"), current: 1350),
        HabitProgressItem(title: "Eat 100g Protein", subtitle: "Nutrition", icon: "🍗", unit: "g", goal: 400, step: 25, accentColor: Color(hex: "#68E08C"), backgroundColor: Color(hex: "#E5FBEA"), current: 370),
        HabitProgressItem(title: "Morning Walk", subtitle: "Movement", icon: "🚶", unit: "steps", goal: 8000, step: 500, accentColor: Color(hex: "#FF914D"), backgroundColor: Color(hex: "#FFE9D8"), current: 4500),
        HabitProgressItem(title: "Meditate", subtitle: "Mindfulness", icon: "🧘", unit: "min", goal: 20, step: 5, accentColor: Color(hex: "#BA8CFF"), backgroundColor: Color(hex: "#F2E7FF"), current: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach($items) { $item in
                    let model = HabitTileModel(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        goal: item.goal,
                        unit: item.unit,
                        step: item.step,
                        accentColor: item.accentColor,
                        backgroundColor: item.backgroundColor
                    )

                    HabitTile(model: model, progress: $item.current) { newValue in
                        saveProgress(for: item, updatedValue: newValue)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(Color.sherpaBackground.ignoresSafeArea())
    }

    private func saveProgress(for item: HabitProgressItem, updatedValue: Double) {
        let percent = item.goal > 0 ? Int((updatedValue / item.goal) * 100) : 0
        Logger.habits.debug("Demo progress updated for sample tile (goal: \(item.goal, privacy: .public), current: \(updatedValue, privacy: .public), percent: \(percent, privacy: .public))")
    }
}
#endif
