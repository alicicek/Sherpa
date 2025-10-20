//
//  SherpaUITestsLaunchTests.swift
//  SherpaUITests
//
//  Created by Ali Cicek on 15/10/2025.
//

import XCTest

final class SherpaUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 5),
            "Sherpa failed to reach the running foreground state after launch."
        )
    }
}
