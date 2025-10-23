//
//  XPStore.swift
//  Sherpa
//
//  Created by Codex on 20/10/2025.
//

import Combine
import Foundation

/// Lightweight persistence wrapper tracking the player's accumulated XP.
@MainActor
final class XPStore: ObservableObject {
    @Published private(set) var xp: XP

    private let defaults: UserDefaults
    private let xpKey = "com.sherpa.user.totalXP"

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        let persistedTotal = userDefaults.object(forKey: xpKey) as? Int ?? 0
        self.xp = XP(total: persistedTotal)
    }

    var totalXP: Int {
        xp.total
    }

    /// Adds positive XP and persists the aggregate total.
    func add(points: Int) {
        guard points > 0 else { return }
        xp = xp.adding(points: points)
        defaults.set(xp.total, forKey: xpKey)
    }
}
