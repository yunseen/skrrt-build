import XCTest

final class CrashProbeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    func testFlow() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        sleep(2)
        shot("01-start")

        let address = app.buttons.element(boundBy: 0)
        address.tap()
        sleep(2)
        shot("02-address-editing")
        alive(app, "after address tap")

        let field = app.textFields.firstMatch
        if field.waitForExistence(timeout: 3) {
            field.typeText("example.com\n")
        } else {
            XCTFail("Address field did not appear")
        }
        sleep(8)
        shot("03-page")
        alive(app, "after load")

        tapIfExists(app.buttons["Back"])
        sleep(1)
        shot("04-after-back")

        let tabs = app.buttons.matching(NSPredicate(format: "label == '1'")).firstMatch
        if tabs.exists {
            tabs.tap()
            sleep(2)
            shot("05-switcher")
            alive(app, "after switcher")
            tapIfExists(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Готово' OR label CONTAINS[c] 'Done'")).firstMatch)
            sleep(1)
        }

        let more = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'More' OR label CONTAINS[c] 'Ещё'")).firstMatch
        if more.exists {
            more.tap()
            sleep(1)
            shot("06-menu")
            alive(app, "after menu")
        }
    }

    private func alive(_ app: XCUIApplication, _ message: String) {
        XCTAssertEqual(app.state, .runningForeground, "App died: \(message)")
    }

    private func tapIfExists(_ element: XCUIElement) {
        if element.exists { element.tap() }
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
