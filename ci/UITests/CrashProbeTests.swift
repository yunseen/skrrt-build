import XCTest

final class CrashProbeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    func testTapEveryButtonOnStart() {
        let first = XCUIApplication()
        first.launch()
        sleep(2)
        shot("start")
        let labels = first.buttons.allElementsBoundByIndex.map { $0.label }
        note("start-buttons", labels.enumerated().map { "\($0.offset): \($0.element)" }.joined(separator: "\n"))
        first.terminate()
        for (index, label) in labels.enumerated() {
            let app = XCUIApplication()
            app.launch()
            sleep(1)
            let buttons = app.buttons.allElementsBoundByIndex
            guard index < buttons.count else { continue }
            buttons[index].tap()
            sleep(2)
            shot(String(format: "start-%02d", index))
            XCTAssertEqual(app.state, .runningForeground, "App died after tapping start button \(index) '\(label)'")
            app.terminate()
        }
    }

    func testLoadPageThenTapEveryButton() {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        let address = app.buttons.allElementsBoundByIndex.first { $0.label.lowercased().contains("search") || $0.label.contains("Поиск") }
        address?.tap()
        sleep(1)
        shot("address-open")
        app.typeText("example.com\n")
        sleep(8)
        shot("page-loaded")
        XCTAssertEqual(app.state, .runningForeground, "App died while loading a page")
        let labels = app.buttons.allElementsBoundByIndex.map { $0.label }
        note("page-buttons", labels.enumerated().map { "\($0.offset): \($0.element)" }.joined(separator: "\n"))
        app.terminate()
        for (index, label) in labels.enumerated() {
            let run = XCUIApplication()
            run.launch()
            sleep(5)
            let buttons = run.buttons.allElementsBoundByIndex
            guard index < buttons.count else { continue }
            buttons[index].tap()
            sleep(2)
            shot(String(format: "page-%02d", index))
            XCTAssertEqual(run.state, .runningForeground, "App died after tapping page button \(index) '\(label)'")
            run.terminate()
        }
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func note(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
