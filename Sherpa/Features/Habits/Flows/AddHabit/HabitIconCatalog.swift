enum HabitIconCategory: String, CaseIterable, Identifiable {
    case health
    case food
    case study
    case finance
    case misc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health: return "Health"
        case .food: return "Food"
        case .study: return "Study"
        case .finance: return "Finance"
        case .misc: return "Misc"
        }
    }
}

struct HabitIconOption: Identifiable, Hashable {
    let id: String
    let systemName: String
    let label: String
    let keywords: [String]
    let category: HabitIconCategory

    var accessibilityLabel: String {
        label
    }
}

enum HabitIconCatalog {
    static let icons: [HabitIconOption] = [
        HabitIconOption(id: "figure.walk", systemName: "figure.walk", label: "Walk", keywords: ["steps", "movement"], category: .health),
        HabitIconOption(id: "heart.fill", systemName: "heart.fill", label: "Heart", keywords: ["cardio", "health"], category: .health),
        HabitIconOption(id: "lungs.fill", systemName: "lungs.fill", label: "Breath", keywords: ["breath", "respire"], category: .health),
        HabitIconOption(id: "moon.zzz.fill", systemName: "moon.zzz.fill", label: "Sleep", keywords: ["rest"], category: .health),
        HabitIconOption(id: "pills.fill", systemName: "pills.fill", label: "Medication", keywords: ["medicine"], category: .health),
        HabitIconOption(id: "drop.fill", systemName: "drop.fill", label: "Hydrate", keywords: ["water"], category: .health),
        HabitIconOption(id: "leaf.fill", systemName: "leaf.fill", label: "Leafy greens", keywords: ["veggies"], category: .food),
        HabitIconOption(id: "takeoutbag.and.cup.and.straw.fill", systemName: "takeoutbag.and.cup.and.straw.fill", label: "Meal prep", keywords: ["food"], category: .food),
        HabitIconOption(id: "carrot.fill", systemName: "carrot.fill", label: "Veggies", keywords: ["food"], category: .food),
        HabitIconOption(id: "cup.and.saucer.fill", systemName: "cup.and.saucer.fill", label: "Tea", keywords: ["drink"], category: .food),
        HabitIconOption(id: "frying.pan.fill", systemName: "frying.pan.fill", label: "Cook", keywords: ["meal"], category: .food),
        HabitIconOption(id: "book.fill", systemName: "book.fill", label: "Read", keywords: ["study"], category: .study),
        HabitIconOption(id: "graduationcap.fill", systemName: "graduationcap.fill", label: "Classes", keywords: ["learn"], category: .study),
        HabitIconOption(id: "brain.head.profile", systemName: "brain.head.profile", label: "Focus", keywords: ["study", "mind"], category: .study),
        HabitIconOption(id: "pencil.and.outline", systemName: "pencil.and.outline", label: "Write", keywords: ["journal"], category: .study),
        HabitIconOption(id: "laptopcomputer", systemName: "laptopcomputer", label: "Laptop", keywords: ["work"], category: .study),
        HabitIconOption(id: "creditcard.fill", systemName: "creditcard.fill", label: "Budget", keywords: ["finance"], category: .finance),
        HabitIconOption(id: "banknote.fill", systemName: "banknote.fill", label: "Savings", keywords: ["finance"], category: .finance),
        HabitIconOption(id: "chart.line.uptrend.xyaxis", systemName: "chart.line.uptrend.xyaxis", label: "Invest", keywords: ["finance"], category: .finance),
        HabitIconOption(id: "dollarsign.circle.fill", systemName: "dollarsign.circle.fill", label: "Pay bills", keywords: ["finance"], category: .finance),
        HabitIconOption(id: "piggy.bank.fill", systemName: "piggy.bank.fill", label: "Piggy bank", keywords: ["finance"], category: .finance),
        HabitIconOption(id: "sparkles", systemName: "sparkles", label: "Sparkles", keywords: ["celebrate"], category: .misc),
        HabitIconOption(id: "target", systemName: "target", label: "Targets", keywords: ["goal"], category: .misc),
        HabitIconOption(id: "globe.americas.fill", systemName: "globe.americas.fill", label: "Global", keywords: ["world"], category: .misc),
        HabitIconOption(id: "gamecontroller.fill", systemName: "gamecontroller.fill", label: "Play", keywords: ["gaming"], category: .misc),
        HabitIconOption(id: "hands.clap.fill", systemName: "hands.clap.fill", label: "Connect", keywords: ["friends"], category: .misc)
    ]

    static var defaultIcon: HabitIconOption {
        icons.first ?? HabitIconOption(
            id: "sparkles",
            systemName: "sparkles",
            label: "Sparkles",
            keywords: [],
            category: .misc
        )
    }

    static func icon(for id: String) -> HabitIconOption? {
        icons.first { $0.id == id }
    }

    static func icons(matching searchText: String, category: HabitIconCategory?) -> [HabitIconOption] {
        icons.filter { option in
            let matchesCategory = category.map { $0 == option.category } ?? true
            guard matchesCategory else { return false }
            guard searchText.isEmpty == false else { return true }
            let haystack = (option.label + " " + option.keywords.joined(separator: " ") + " " + option.systemName).lowercased()
            return haystack.contains(searchText.lowercased())
        }
    }
}
