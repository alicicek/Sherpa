import XCTest

struct HabitsHomeScreen {
    let app: XCUIApplication

    var addHabitButton: XCUIElement {
        app.buttons[L10nStrings.addHabitButton]
    }

    var isDisplayingHome: Bool {
        app.tabBars.firstMatch.waitForExistence(timeout: 2) && addHabitButton.waitForExistence(timeout: 2)
    }

    @discardableResult
    func tapAddHabit() -> HabitsHomeScreen {
        addHabitButton.tap()
        return self
    }
}

private enum L10nStrings {
    static let addHabitButton = "Add a new habit"
}
