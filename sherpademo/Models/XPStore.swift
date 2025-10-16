//
//  XPStore.swift
//  sherpademo
//
//  Created by Codex on 20/10/2025.
//

import Foundation
import Combine

/// Lightweight persistence wrapper tracking the player's accumulated XP.
@MainActor
final class XPStore: ObservableObject {
    @Published private(set) var totalXP: Int

    private let defaults: UserDefaults
    private let xpKey = "com.sherpa.user.totalXP"

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        let persisted = userDefaults.object(forKey: xpKey) as? Int ?? 0
        self.totalXP = persisted
    }

    /// Adds positive XP and persists the aggregate total.
    func add(points: Int) {
        guard points > 0 else { return }
        totalXP += points
        defaults.set(totalXP, forKey: xpKey)
    }
}
