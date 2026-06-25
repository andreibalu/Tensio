import XCTest
@testable import Tensio
import TensioCore

final class TensioAppSmokeTests: XCTestCase {
    func testMainTabsMatchMVPPlan() {
        XCTAssertEqual(MainTab.allCases.map(\.rawValue), [
            "today",
            "log",
            "medicines",
            "report",
            "settings"
        ])
    }

    func testAppTargetLinksTensioCore() {
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 118, diastolic: 76), .normal)
    }
}
