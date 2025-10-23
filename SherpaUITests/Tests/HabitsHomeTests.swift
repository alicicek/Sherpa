import XCTest

final class HabitsHomeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLaunchDisplaysHabitsHome() {
        app.launch()
        let home = HabitsHomeScreen(app: app)
        XCTAssertTrue(home.isDisplayingHome)
    }
}
