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

extension CrashProbeTests {
    func testM_closeTabInSwitcher() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "-skrrt-reset"]
        app.launch()
        sleep(4)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.93)).tap()
        let newTab = app.buttons.matching(NSPredicate(format: "label IN {'Новая вкладка','New Tab'}")).firstMatch
        XCTAssertTrue(newTab.waitForExistence(timeout: 5), "menu item missing")
        newTab.tap()
        sleep(2)
        let tabsButton = app.buttons["2"]
        XCTAssertTrue(tabsButton.waitForExistence(timeout: 5), "tab count should be 2")
        tabsButton.tap()
        let closeButtons = app.buttons.matching(NSPredicate(format: "label IN {'Закрыть вкладку','Close Tab'}"))
        XCTAssertTrue(closeButtons.firstMatch.waitForExistence(timeout: 6), "switcher has no close buttons")
        XCTAssertEqual(closeButtons.count, 2, "two cards expected")
        closeButtons.element(boundBy: 0).tap()
        sleep(2)
        let shotImage = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shotImage.name = "after-close"
        shotImage.lifetime = .keepAlways
        add(shotImage)
        let done = app.buttons.matching(NSPredicate(format: "label IN {'Готово','Done'}")).firstMatch
        XCTAssertTrue(done.exists, "switcher closed instead of closing the tab")
        XCTAssertEqual(closeButtons.count, 1, "tab was not closed")
    }
}

extension CrashProbeTests {
    private func button(_ app: XCUIApplication, _ fragments: [String]) -> XCUIElement {
        let format = fragments.map { _ in "label CONTAINS %@" }.joined(separator: " OR ")
        return app.buttons.matching(NSPredicate(format: format, argumentArray: fragments)).firstMatch
    }

    private func openSettingsScreen(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.93)).tap()
        let item = button(app, ["Настройки", "Settings"])
        XCTAssertTrue(item.waitForExistence(timeout: 5), "Settings item missing")
        item.tap()
        sleep(2)
    }

    private func openPluginsScreen(_ app: XCUIApplication) {
        openSettingsScreen(app)
        let row = button(app, ["Плагины", "Plugins"])
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Plugins row missing")
        row.tap()
        sleep(2)
    }

    private func showInstalled(_ app: XCUIApplication) {
        let segment = app.segmentedControls.buttons.matching(NSPredicate(format: "label CONTAINS 'Установлено' OR label CONTAINS 'Installed'")).firstMatch
        XCTAssertTrue(segment.waitForExistence(timeout: 5), "Installed segment missing")
        segment.tap()
        sleep(1)
    }

    private func createScriptPlugin(_ app: XCUIApplication, name: String) {
        let add = app.navigationBars.buttons.matching(NSPredicate(format: "label IN {'Добавить плагин','Add Plugin'}")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), "Add Plugin button missing")
        add.tap()
        let newScript = button(app, ["Новый скрипт", "New Script"])
        XCTAssertTrue(newScript.waitForExistence(timeout: 4), "New Script option missing")
        newScript.tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "editor name field missing")
        field.tap()
        field.typeText(name)
        let save = button(app, ["Сохранить", "Save"])
        XCTAssertTrue(save.isEnabled, "Save should be enabled")
        save.tap()
        sleep(2)
    }

    func testN_pluginLifecycle() {
        let app = launchFresh()
        openPluginsScreen(app)
        shot("plugins-store")
        createScriptPlugin(app, name: "Тест")
        showInstalled(app)
        let row = app.staticTexts["Тест"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "new plugin missing from Installed")
        shot("plugin-installed")
        row.tap()
        sleep(2)
        shot("plugin-window")
        let rename = button(app, ["Переименовать", "Rename"])
        XCTAssertTrue(rename.waitForExistence(timeout: 4), "plugin window has no Rename")
        rename.tap()
        let nameField = app.alerts.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 4), "rename alert missing")
        nameField.typeText("2")
        app.alerts.buttons.matching(NSPredicate(format: "label IN {'Сохранить','Save'}")).firstMatch.tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Тест2"].waitForExistence(timeout: 4), "plugin was not renamed")
        let remove = button(app, ["Удалить плагин", "Remove Plugin"])
        XCTAssertTrue(remove.waitForExistence(timeout: 4), "plugin window has no Remove")
        remove.tap()
        let confirm = app.sheets.buttons.matching(NSPredicate(format: "label IN {'Удалить плагин','Remove Plugin'}")).firstMatch
        if confirm.waitForExistence(timeout: 3) { confirm.tap() }
        sleep(2)
        XCTAssertFalse(app.staticTexts["Тест2"].exists, "plugin was not removed")
    }

    func testO_pluginRunsOnPage() {
        let app = launchFresh()
        openPluginsScreen(app)
        createScriptPlugin(app, name: "Тест")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        let done = button(app, ["Готово", "Done"])
        XCTAssertTrue(done.waitForExistence(timeout: 4), "Done missing")
        done.tap()
        sleep(2)
        let bar = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Поиск или адрес' OR label CONTAINS[c] 'Search or enter'")).firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "address bar missing")
        bar.tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5), "search field missing")
        app.textFields.firstMatch.typeText("example.com")
        app.textFields.firstMatch.typeText("\n")
        let toast = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Hello from example.com'")).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 20), "the plugin did not run on the page")
        shot("plugin-page")
    }

    func testP_settingsPagesOpen() {
        let app = launchFresh()
        openSettingsScreen(app)
        shot("settings-hub")
        let pages = ["Поиск", "Главный экран", "Оформление", "Приватность", "Просмотр", "Плагины", "О приложении"]
        for page in pages {
            let row = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS %@", page)).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5), "row \(page) missing")
            row.tap()
            sleep(2)
            shot("page-\(page)")
            XCTAssertEqual(app.state, .runningForeground, "App died on \(page)")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
    }

    func testQ_storeInstallAndSiteWindow() {
        let app = launchFresh()
        openPluginsScreen(app)
        // The store lists the plugins and one of them can be installed with a single tap.
        let name = app.staticTexts["Чёрно-белый режим"]
        let search = app.searchFields.firstMatch
        if search.waitForExistence(timeout: 4) {
            search.tap()
            search.typeText("Чёрно")
        }
        XCTAssertTrue(name.waitForExistence(timeout: 10), "store does not list a plugin")
        shot("store-search")
        let get = app.buttons.matching(NSPredicate(format: "label IN {'Получить','Get'}")).firstMatch
        XCTAssertTrue(get.waitForExistence(timeout: 5), "Get button missing")
        get.tap()
        let installedPill = app.buttons.matching(NSPredicate(format: "label IN {'Установлено','Installed'}")).firstMatch
        XCTAssertTrue(installedPill.waitForExistence(timeout: 20), "plugin was not installed")
        shot("store-installed")
        // Back to the browser and open a page, then the site window.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        button(app, ["Готово", "Done"]).tap()
        sleep(2)
        loadPageFresh(app)
        let puzzle = app.buttons.matching(NSPredicate(format: "label IN {'Этот сайт','This Site'}")).firstMatch
        XCTAssertTrue(puzzle.waitForExistence(timeout: 8), "site button missing in the address bar")
        puzzle.tap()
        sleep(2)
        shot("site-window")
        XCTAssertTrue(app.staticTexts["Чёрно-белый режим"].waitForExistence(timeout: 5), "installed plugin is not listed for the site")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Cookie' OR label CONTAINS 'Cookies'")).firstMatch.exists, "cookies tool missing")
        XCTAssertEqual(app.state, .runningForeground, "App died in the site window")
    }

    func testR_cookieManager() {
        let app = launchFresh()
        loadPageFresh(app)
        let puzzle = app.buttons.matching(NSPredicate(format: "label IN {'Этот сайт','This Site'}")).firstMatch
        XCTAssertTrue(puzzle.waitForExistence(timeout: 8), "site button missing")
        puzzle.tap()
        sleep(2)
        let cookies = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS 'Cookie'")).firstMatch
        XCTAssertTrue(cookies.waitForExistence(timeout: 5), "cookies row missing")
        cookies.tap()
        sleep(2)
        shot("cookie-manager")
        XCTAssertTrue(app.navigationBars["Cookie"].exists || app.navigationBars["Cookies"].exists, "cookie manager did not open")
        XCTAssertEqual(app.state, .runningForeground, "App died in the cookie manager")
    }

    func testS_hideElement() {
        let app = launchFresh()
        loadPageFresh(app)
        let puzzle = app.buttons.matching(NSPredicate(format: "label IN {'Этот сайт','This Site'}")).firstMatch
        XCTAssertTrue(puzzle.waitForExistence(timeout: 8), "site button missing")
        puzzle.tap()
        sleep(2)
        let hide = button(app, ["Скрыть элемент", "Hide an Element"])
        XCTAssertTrue(hide.waitForExistence(timeout: 5), "Hide an Element missing")
        hide.tap()
        let hint = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Нажмите на элемент' OR label CONTAINS 'Tap the element'")).firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 6), "the picker did not start")
        shot("picker-started")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        sleep(1)
        let confirm = app.buttons.matching(NSPredicate(format: "label IN {'Скрыть','Hide'}")).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "the picker has no Hide button after a tap")
        shot("picker-selected")
        confirm.tap()
        sleep(2)
        XCTAssertFalse(hint.exists, "the picker did not close")
        // The rule is listed in the site window.
        puzzle.tap()
        sleep(2)
        let hidden = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS 'Скрытые элементы' OR label CONTAINS 'Hidden Elements'")).firstMatch
        XCTAssertTrue(hidden.waitForExistence(timeout: 5), "Hidden Elements row missing")
        shot("hidden-count")
        XCTAssertEqual(app.state, .runningForeground, "App died while hiding an element")
    }
}
