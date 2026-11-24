import XCTest

final class CrashProbeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        sleep(2)
        return app
    }

    private func loadPage(_ app: XCUIApplication) {
        app.buttons.element(boundBy: 0).tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "address field missing")
        field.typeText("example.com\n")
        sleep(8)
        alive(app, "after load")
    }

    private func tapAt(_ app: XCUIApplication, _ x: Double, _ y: Double, _ name: String) {
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
        sleep(2)
        shot(name)
        alive(app, "after tap \(name)")
    }

    func testA_switcherOnStartPage() {
        let app = launch()
        tapAt(app, 0.74, 0.93, "tabs-button-startpage")
        tapAt(app, 0.80, 0.93, "done")
    }

    func testB_loadThenIdle() {
        let app = launch()
        loadPage(app)
        sleep(15)
        alive(app, "after idle")
    }

    func testC_tapBlankAfterLoad() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.5, 0.3, "blank-page")
    }

    func testD_tapShieldAfterLoad() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.5, 0.09, "shield")
    }

    func testE_tapBookAfterLoad() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.58, 0.93, "book")
    }

    func testF_tapReloadAfterLoad() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.90, 0.86, "reload")
    }

    func testG_tapTabsAfterLoad() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.74, 0.93, "tabs-button")
        tapAt(app, 0.80, 0.93, "done")
    }

    func testH_swipeThenTabs() {
        let app = launch()
        loadPage(app)
        app.swipeUp()
        sleep(1)
        alive(app, "after swipe")
        tapAt(app, 0.74, 0.93, "tabs-button")
    }

    private func alive(_ app: XCUIApplication, _ message: String) {
        XCTAssertEqual(app.state, .runningForeground, "App died: \(message)")
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
