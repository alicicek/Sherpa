//
//  KeyboardObserver.swift
//  Sherpa
//
//  Shared observable for monitoring keyboard height changes.
//

import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class KeyboardObserver: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        Publishers.Merge(willChange, willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }

                guard let userInfo = notification.userInfo,
                      let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let windowScene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first else {
                    self.currentHeight = 0
                    return
                }

                let screenHeight = windowScene.screen.bounds.height
                let overlap = max(0, screenHeight - endFrame.origin.y)
                self.currentHeight = overlap
            }
            .store(in: &cancellables)
    }
}
