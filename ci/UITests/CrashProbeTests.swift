import XCTest

final class CrashProbeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "-skrrt-reset"]
        app.launch()
        sleep(3)
        return app
    }

    private func addressBar(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поиск или адрес' OR label CONTAINS[c] 'Search or enter'")).firstMatch
    }

    private func openSearch(_ app: XCUIApplication) {
        let bar = addressBar(app)
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "address bar missing")
        bar.tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5), "search field missing")
        sleep(1)
    }

    private func loadPage(_ app: XCUIApplication, _ address: String = "example.com") {
        openSearch(app)
        app.textFields.firstMatch.typeText(address)
        app.textFields.firstMatch.typeText("\n")
        sleep(8)
        alive(app, "after load")
    }

    private func tapAt(_ app: XCUIApplication, _ x: Double, _ y: Double, _ name: String) {
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
        sleep(2)
        shot(name)
        alive(app, "after tap \(name)")
    }

    func testA_startPage() {
        let app = launch()
        sleep(4)
        shot("start-page")
        alive(app, "start page idle")
        tapAt(app, 0.5, 0.25, "tap-on-mascots")
        tapAt(app, 0.5, 0.25, "tap-on-mascots-2")
    }

    func testB_searchTypeAndGo() {
        let app = launch()
        openSearch(app)
        shot("search-open")
        alive(app, "search open")
        app.textFields.firstMatch.typeText("swift")
        sleep(3)
        shot("search-typed")
        let go = app.buttons.matching(NSPredicate(format: "label IN {'Перейти','Go'}")).firstMatch
        XCTAssertTrue(go.waitForExistence(timeout: 3), "Go button missing")
        go.tap()
        sleep(10)
        shot("search-result")
        alive(app, "after go")
        tapAt(app, 0.5, 0.4, "tap-result")
    }

    func testC_grabberKeyboard() {
        let app = launch()
        openSearch(app)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "keyboard should be up")
        let field = app.textFields.firstMatch.frame
        let screen = app.frame
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: (field.minY - 14) / screen.height))
        let down = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: min(0.97, (field.minY + 120) / screen.height)))
        start.press(forDuration: 0.1, thenDragTo: down)
        sleep(2)
        shot("after-drag-down")
        XCTAssertFalse(app.keyboards.firstMatch.exists, "keyboard should hide after dragging down")
        alive(app, "after drag down")
        let field2 = app.textFields.firstMatch.frame
        let start2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: (field2.minY - 14) / screen.height))
        let up = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: max(0.3, (field2.minY - 140) / screen.height)))
        start2.press(forDuration: 0.1, thenDragTo: up)
        sleep(2)
        shot("after-drag-up")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard should show after dragging up")
        alive(app, "after drag up")
    }

    func testD_loadThenTaps() {
        let app = launch()
        loadPage(app)
        shot("page-loaded")
        tapAt(app, 0.5, 0.3, "blank-page")
        tapAt(app, 0.90, 0.86, "reload")
        sleep(4)
        tapAt(app, 0.5, 0.09, "shield")
        app.swipeUp()
        sleep(1)
        alive(app, "after swipe")
        tapAt(app, 0.58, 0.93, "library")
        tapAt(app, 0.5, 0.15, "dismiss-library")
    }

    func testE_switcher() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.74, 0.93, "tabs-button")
        tapAt(app, 0.80, 0.93, "done")
        tapAt(app, 0.74, 0.93, "tabs-button-again")
    }

    func testF_settings() {
        let app = launch()
        loadPage(app)
        tapAt(app, 0.90, 0.93, "menu")
        let settings = app.buttons.matching(NSPredicate(format: "label IN {'Настройки','Settings'}")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 4), "Settings item missing")
        settings.tap()
        sleep(2)
        shot("settings-1")
        alive(app, "settings open")
        app.swipeUp()
        sleep(1)
        shot("settings-2")
        app.swipeUp()
        sleep(1)
        shot("settings-3")
        app.swipeUp()
        sleep(1)
        shot("settings-4")
        alive(app, "settings scrolled")
    }

    func testG_addShortcut() {
        let app = launch()
        sleep(2)
        let add = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Добавить' OR label CONTAINS[c] 'Add'")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add tile missing")
        add.tap()
        sleep(1)
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 4), "editor field missing")
        field.tap()
        field.typeText("github.com")
        sleep(10)
        shot("shortcut-editor")
        let save = app.buttons.matching(NSPredicate(format: "label IN {'Сохранить','Save'}")).firstMatch
        XCTAssertTrue(save.exists, "Save button missing")
        save.tap()
        sleep(2)
        shot("shortcut-added")
        alive(app, "after add shortcut")
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

extension CrashProbeTests {
    private func hitInfo(_ element: XCUIElement) -> String {
        "exists=\(element.exists) hittable=\(element.isHittable)"
    }

    func testH_tabsButtonOpensSwitcherOnPage() {
        let app = launchFresh()
        loadPageFresh(app)
        let tabs = app.buttons["1"]
        XCTAssertTrue(tabs.waitForExistence(timeout: 5), "tabs button missing")
        let info = hitInfo(tabs)
        tabs.tap()
        let done = app.buttons.matching(NSPredicate(format: "label IN {'Готово','Done'}")).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 6), "switcher did not open (\(info))")
    }

    func testI_libraryButtonOpensSheetOnPage() {
        let app = launchFresh()
        loadPageFresh(app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.93)).tap()
        let title = app.buttons.matching(NSPredicate(format: "label IN {'Закладки','Bookmarks'}")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 6), "library did not open")
    }

    func testJ_menuButtonOpensOnPage() {
        let app = launchFresh()
        loadPageFresh(app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.93)).tap()
        let item = app.buttons.matching(NSPredicate(format: "label IN {'Новая вкладка','New Tab'}")).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "menu did not open")
    }

    func testK_addressBarOpensSearchOnPage() {
        let app = launchFresh()
        loadPageFresh(app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.86)).tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5), "search did not open from the address bar")
    }

    func testL_startPageBottomButtons() {
        let app = launchFresh()
        let tabs = app.buttons["1"]
        XCTAssertTrue(tabs.waitForExistence(timeout: 8), "tabs button missing")
        tabs.tap()
        let done = app.buttons.matching(NSPredicate(format: "label IN {'Готово','Done'}")).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 6), "switcher did not open on start page")
        done.tap()
        sleep(2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.93)).tap()
        let title = app.buttons.matching(NSPredicate(format: "label IN {'Закладки','Bookmarks'}")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 6), "library did not open on start page")
    }

    private func launchFresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "-skrrt-reset"]
        app.launch()
        sleep(3)
        return app
    }

    private func loadPageFresh(_ app: XCUIApplication) {
        let bar = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поиск или адрес' OR label CONTAINS[c] 'Search or enter'")).firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "address bar missing")
        bar.tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5), "search field missing")
        app.textFields.firstMatch.typeText("example.com")
        app.textFields.firstMatch.typeText("\n")
        sleep(8)
    }
}
