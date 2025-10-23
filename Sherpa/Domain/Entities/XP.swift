import Foundation

/// Represents an immutable XP total that can be incremented.
struct XP: Codable, Equatable {
    private(set) var total: Int

    init(total: Int = 0) {
        self.total = max(0, total)
    }

    func adding(points: Int) -> XP {
        guard points > 0 else { return self }
        return XP(total: total + points)
    }
}
