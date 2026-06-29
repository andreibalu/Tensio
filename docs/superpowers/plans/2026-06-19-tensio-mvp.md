# Tensio MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Tensio iOS MVP: a premium, senior-friendly, local-first blood pressure companion that makes manual reading capture fast, classifies readings conservatively, guides correct home monitoring, tracks medicines, and creates doctor-ready reports.

**Architecture:** Tensio is a SwiftUI iOS app backed by SwiftData and a small pure Swift package named `TensioCore` for deterministic domain rules, report summaries, and export formatting. The app has no server, account system, analytics SDK, LLM, camera scanning, or Bluetooth device sync in the MVP; those are later integrations behind future service boundaries.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Charts, UserNotifications, HealthKit, PDFKit/UIGraphicsPDFRenderer, XCTest, XCUITest, iOS 17.0 minimum deployment target.

## Global Constraints

- Greenfield repo: `/Users/andreibalu/CODE/xcode/Tensio` is empty at plan creation time; Task 1 initializes the repo and app scaffold.
- App name: `Tensio`.
- Name layering: repo folder, Xcode project, Xcode scheme, app target, marketing name, and visible app name must all be `Tensio`.
- Bundle identifier for local builds: `com.andreibalu.tensio`.
- Assumed support email for scaffolded legal docs: `support@tensio.app`.
- Platform: iPhone only for MVP with `TARGETED_DEVICE_FAMILY = 1`; iOS 17.0 minimum; iPad support is a post-MVP release after every screen is tested on iPad.
- Product promise: save a manual blood pressure reading in under 10 seconds after opening the entry screen.
- Privacy posture: no account, no remote backend, no analytics SDK, no third-party SDKs, no network calls in MVP.
- Day-zero repo assets: Task 1 must create `VERSION`, `agents.md`, `support.md`, `privacy-policy.md`, `EULA.md`, `Tensio/Resources/PrivacyInfo.xcprivacy`, and `ci_scripts/ci_post_clone.sh`.
- Privacy docs: any later change to permissions, HealthKit, backup, networking, subscriptions, or data storage must update `privacy-policy.md`, `support.md`, `EULA.md`, `PrivacyInfo.xcprivacy`, and `agents.md` in the same commit.
- SwiftData future sync: do not use `@Attribute(.unique)` on models; define explicit relationship inverses; in-memory test containers must use `cloudKitDatabase: .none`; fields added after the first TestFlight build must use nullable backing storage with a computed non-optional accessor.
- Manual-entry persistence must fail closed: if a local save throws, keep entered values visible and surface retry guidance; never clear a reading draft before successful save.
- Architecture style: use lightweight MVVM; views own `@Query`, `@AppStorage`, and UI state; `@MainActor @Observable` view models own async workflows; services are protocol typed with default concrete implementations and test mocks.
- Medical safety: Tensio logs, explains, and shares readings from external blood pressure monitors; it must never claim to measure blood pressure using the phone alone.
- Medical safety: Tensio must not diagnose hypertension, prescribe treatment, or advise starting, stopping, or changing medication.
- Clinical categories: use the American Heart Association patient-facing categories: normal `<120 and <80`, elevated `120-129 and <80`, stage 1 `130-139 or 80-89`, stage 2 `>=140 or >=90`, severe `>180 and/or >120`.
- Severe reading flow: for `systolic > 180 or diastolic > 120`, show deterministic guidance to wait at least 1 minute, take another reading, ask about emergency symptoms, and show emergency-services guidance if symptoms are present.
- Severe reading flow implementation detail: preserve an explicit unanswered emergency-symptom state in UI until user responds; never treat an unanswered state as "no symptoms."
- Home monitoring protocol: 2 consecutive measurements at least 1 minute apart, twice daily morning and evening, for at least 4 days and ideally 7 days; discard day 1 when calculating the protocol average shown in reports.
- Clinical source links for implementers and reviewers:
  - AHA categories and severe guidance: https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings
  - NICE HBPM protocol and validated device guidance: https://www.nice.org.uk/guidance/ng136/chapter/recommendations
- Accessibility: all tappable controls in primary flows must be at least `56x56 pt`, VoiceOver labels must be explicit, Dynamic Type must work through Accessibility 3, and color must never be the only status signal.
- Visual direction: premium clinical calm, not a generic health app; use the design tokens in "Design System Contract" exactly unless a later reviewed design task changes the token file and screenshots.
- Non-MVP features: camera scan, Bluetooth sync, AI chat/summaries, caregiver sharing, cloud account sync, multi-user profiles, widgets, and subscriptions.
- Non-MVP data flows: destructive backup restore UI is post-MVP; MVP includes encrypted backup export and tested backup decoding support only.
- Commit policy: each task ends with one commit whose message is listed in that task.
- Verification policy: each task must run its listed tests before committing; app build/test tasks must prefer XcodeBuildMCP when available.
- Local guide source: incorporate startup lessons from `/Users/andreibalu/CODE/learnings/00-quickstart-new-app.md`, `/Users/andreibalu/CODE/learnings/02-architecture-patterns.md`, `/Users/andreibalu/CODE/learnings/03-ios-platform-gotchas.md`, and `/Users/andreibalu/CODE/learnings/04-tooling-and-workflow.md`.

---

## MVP Product Scope

The first release must support these user outcomes:

- A senior user can open Tensio, enter systolic, diastolic, and optional pulse using large controls, save the reading, and immediately understand the category without alarmist language.
- A severe reading is handled by hard-coded rules, not AI copy.
- A user can add optional context chips after the required numbers: arm, posture, symptoms, stress, caffeine, exercise, missed medicine, and notes.
- A user can follow a 7-day home monitoring plan with morning/evening reminders and two readings per session.
- A user can track medicines, schedules, skipped/late/taken doses, refill dates, and side effects.
- A user can view Today, Log, Medicines, Report, and Settings from a persistent tab bar.
- A user can export a one-page doctor summary PDF, a full reading log PDF, and a CSV.
- A user can opt into Apple Health import/export from Settings.
- A user can export an encrypted local backup file protected by a passphrase; decode support is covered by tests so restore UI can be added later without changing the file format.

## Design System Contract

Use native iOS components where they improve accessibility. Custom styling must stay restrained and consistent.

**Palette**

- `porcelain`: `#F7F6F2` main background
- `ink`: `#1E2320` primary text
- `evergreen`: `#173B35` navigation, selected controls, premium anchor color
- `warmGraphite`: `#4D5651` secondary text
- `clinicalBlue`: `#2F6FBB` information and HealthKit connection
- `brass`: `#B99452` dividers, protocol progress, premium accent
- `mist`: `#E7ECE8` surfaces and separators
- `signalRed`: `#B83A3A` severe status and emergency affordance

**Typography**

- Display readings: `.system(size: 64, weight: .semibold, design: .rounded)`, Dynamic Type scaled.
- Screen titles: `.system(.largeTitle, design: .rounded).weight(.semibold)`.
- Body: `.system(.body, design: .default)`.
- Labels/data: `.system(.caption, design: .monospaced).weight(.medium)` for BP units, averages, and timestamps.

**Layout**

- Primary navigation is a bottom tab bar with text labels and SF Symbols.
- Primary actions are full-width or half-width controls with a minimum height of `56 pt`.
- Reading cards use an 8 pt corner radius, not pill-heavy styling.
- Do not put cards inside cards.
- Do not use decorative gradient blobs, orbs, bokeh, or purely ornamental illustrations.
- The app uses a "clinic slip" signature element: reading and report summaries look like a refined paper measurement slip with one brass rule, large numerals, and quiet metadata. This is the single memorable visual motif.

**Copy**

- Use plain, direct wording: "Save reading", "Take another reading", "Call emergency services", "Share report".
- Do not use cheerful medical reassurance after high readings.
- Always pair a category with next action: "Track this trend", "Discuss with your clinician", or the severe reading flow.

## File Ownership Map

Task 1 creates the base structure. Later tasks only add or modify their listed files unless a test reveals a compile failure in a dependency interface.

```text
Package.swift
VERSION
agents.md
support.md
privacy-policy.md
EULA.md
ci_scripts/
  ci_post_clone.sh
Sources/TensioCore/
  BloodPressureCategory.swift
  BloodPressureReading.swift
  ClinicalGuidance.swift
  MonitoringProtocol.swift
  ReportSummary.swift
  CSVExport.swift
  BackupEnvelope.swift
Tests/TensioCoreTests/
  BloodPressureCategoryTests.swift
  MonitoringProtocolTests.swift
  ReportSummaryTests.swift
  CSVExportTests.swift
  BackupEnvelopeTests.swift
Tensio.xcodeproj/
Tensio/
  App/
    TensioApp.swift
    AppRootView.swift
    MainTab.swift
  Design/
    TensioTheme.swift
    TensioComponents.swift
  Persistence/
    TensioModelContainer.swift
    BPReadingRecord.swift
    MedicationRecord.swift
    DoseLogRecord.swift
    MonitoringSessionRecord.swift
    Repositories.swift
  Features/
    Onboarding/
      OnboardingView.swift
      MeasurementTechniqueView.swift
    Entry/
      ReadingEntryView.swift
      ReadingContextView.swift
      LargeNumberPad.swift
    Dashboard/
      TodayView.swift
      ReadingSlipView.swift
      TrendChartView.swift
      ReadingLogView.swift
    Coach/
      MonitoringPlanView.swift
      MeasurementTimerView.swift
      ReminderScheduler.swift
    Medications/
      MedicationCenterView.swift
      MedicationEditorView.swift
      DoseRowView.swift
    Reports/
      ReportsView.swift
      DoctorSummaryPDFRenderer.swift
      FullLogPDFRenderer.swift
      ShareExportService.swift
    Settings/
      PrivacySettingsView.swift
      HealthKitSyncService.swift
      BackupImportExportService.swift
  Resources/
    Localizable.xcstrings
    PrivacyInfo.xcprivacy
  Tensio.entitlements
TensioTests/
  PersistenceTests.swift
  ReminderSchedulerTests.swift
  HealthKitSyncServiceTests.swift
  BackupImportExportServiceTests.swift
TensioUITests/
  TensioSmokeUITests.swift
  SeniorAccessibilityUITests.swift
```

## Subagent Execution Rules

- Use one implementer subagent per task, in order.
- Do not dispatch implementation subagents in parallel because project files and Swift interfaces change sequentially.
- After each implementer reports done, run a task review subagent against that task's diff.
- Fix Critical and Important review findings before starting the next task.
- A task is complete only after tests pass, review passes, and the commit exists.

---

### Task 1: Greenfield Project Scaffold

**Files:**
- Create: `.gitignore`
- Create: `VERSION`
- Create: `agents.md`
- Create: `support.md`
- Create: `privacy-policy.md`
- Create: `EULA.md`
- Create: `ci_scripts/ci_post_clone.sh`
- Create: `Package.swift`
- Create: `Sources/TensioCore/TensioCore.swift`
- Create: `Tests/TensioCoreTests/TensioCoreSmokeTests.swift`
- Create: `Tensio.xcodeproj/project.pbxproj`
- Create: `Tensio/App/TensioApp.swift`
- Create: `Tensio/App/AppRootView.swift`
- Create: `Tensio/App/MainTab.swift`
- Create: `Tensio/Resources/Localizable.xcstrings`
- Create: `Tensio/Resources/PrivacyInfo.xcprivacy`
- Create: `TensioTests/TensioAppSmokeTests.swift`
- Create: `TensioUITests/TensioSmokeUITests.swift`

**Interfaces:**
- Produces: Swift package module `TensioCore`.
- Produces: iOS app target `Tensio`, unit test target `TensioTests`, UI test target `TensioUITests`.
- Produces: app entry point `TensioApp`.

- [ ] **Step 1: Initialize Git if needed**

Run:

```bash
git status --short
```

Expected if repo is not initialized:

```text
fatal: not a git repository (or any of the parent directories): .git
```

If that exact fatal message appears, run:

```bash
git init
```

Expected:

```text
Initialized empty Git repository
```

- [ ] **Step 2: Add day-zero repo assets**

Create `VERSION`:

```text
0.1
```

Create `agents.md`:

```markdown
# Tensio Working Notes

## Product

Tensio is a local-first, no-account iOS blood pressure companion for seniors and caregivers preparing for clinician visits.

## Non-negotiables

- App, scheme, project, target, and visible marketing name are all `Tensio`.
- Bundle identifier is `com.andreibalu.tensio`.
- MVP is iPhone-only with `TARGETED_DEVICE_FAMILY = 1`.
- No server, account system, analytics SDK, third-party SDK, LLM, camera scanning, or Bluetooth sync in MVP.
- Tensio logs readings from external blood pressure monitors; it never claims to measure blood pressure from the phone alone.
- Severe reading guidance is deterministic and follows the AHA thresholds listed in the implementation plan.
- Every permission, HealthKit, backup, networking, or data-storage change updates `privacy-policy.md`, `support.md`, `EULA.md`, and `PrivacyInfo.xcprivacy` in the same commit.

## Implementation

- Use lightweight MVVM.
- Services are protocol typed with default concrete implementations.
- SwiftData models avoid `@Attribute(.unique)` so future CloudKit sync remains possible.
- UI must support Dynamic Type through Accessibility 3 and primary controls must be at least 56 pt tall.
```

Create `support.md`:

```markdown
# Tensio Support

For support, email the developer at support@tensio.app.

Tensio stores blood pressure readings on device. It does not diagnose medical conditions, measure blood pressure, or recommend medication changes.
```

Create `privacy-policy.md`:

```markdown
# Tensio Privacy Policy

Tensio is local-first. The MVP stores readings, medicine names, dose logs, reminder preferences, and settings on the user's device.

Tensio does not require an account, does not use an analytics SDK, does not sell data, and does not send readings to a Tensio server.

If the user connects Apple Health, Tensio asks permission to read and write blood pressure samples through HealthKit. The user can revoke HealthKit permission in iOS Settings.

If the user exports a report or backup, the user chooses where to share or store that file.
```

Create `EULA.md`:

```markdown
# Tensio End User License Agreement

Tensio is licensed under Apple's Standard End User License Agreement.

Tensio is an informational logging tool. It is not a medical device, does not measure blood pressure, does not diagnose conditions, and does not recommend medication changes.
```

Create `ci_scripts/ci_post_clone.sh`:

```bash
#!/bin/bash
set -e
VERSION_FILE="$CI_PRIMARY_REPOSITORY_PATH/VERSION"
BASE_VERSION=$(cat "$VERSION_FILE")
if [ "$CI_BRANCH" = "main" ]; then
    MARKETING_VERSION="$BASE_VERSION"
else
    MARKETING_VERSION="${BASE_VERSION}.${CI_BUILD_NUMBER}"
fi
PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/Tensio.xcodeproj/project.pbxproj"
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $MARKETING_VERSION;/g" "$PBXPROJ"
sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" "$PBXPROJ"
```

Create `Tensio/Resources/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Write the pure Swift package smoke test**

Create `Tests/TensioCoreTests/TensioCoreSmokeTests.swift`:

```swift
import XCTest
@testable import TensioCore

final class TensioCoreSmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(TensioCore.name, "TensioCore")
    }
}
```

- [ ] **Step 4: Run the smoke test and verify it fails**

Run:

```bash
swift test --filter TensioCoreSmokeTests/testModuleLoads
```

Expected: FAIL because `Package.swift` or `TensioCore` does not exist.

- [ ] **Step 5: Add Swift package files**

Create `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TensioCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TensioCore", targets: ["TensioCore"])
    ],
    targets: [
        .target(name: "TensioCore"),
        .testTarget(name: "TensioCoreTests", dependencies: ["TensioCore"])
    ]
)
```

Create `Sources/TensioCore/TensioCore.swift`:

```swift
public enum TensioCore {
    public static let name = "TensioCore"
}
```

- [ ] **Step 6: Run the Swift package smoke test**

Run:

```bash
swift test --filter TensioCoreSmokeTests/testModuleLoads
```

Expected: PASS.

- [ ] **Step 7: Create the Xcode iOS app project**

Create an Xcode project named `Tensio` with these exact settings:

```text
Product Name: Tensio
Organization Identifier: com.andreibalu
Bundle Identifier: com.andreibalu.tensio
Interface: SwiftUI
Language: Swift
Minimum Deployment: iOS 17.0
Targeted Device Family: iPhone
Use SwiftData: enabled
Include Tests: enabled
Marketing Version: 0.1
Current Project Version: 1
```

Add the local Swift package at repo root (`Package.swift`) to the app target. Add `Tensio/Resources/PrivacyInfo.xcprivacy` to the app target resources.

Expected paths after creation:

```text
Tensio.xcodeproj/project.pbxproj
Tensio/App/TensioApp.swift
Tensio/App/AppRootView.swift
Tensio/App/MainTab.swift
Tensio/Resources/PrivacyInfo.xcprivacy
TensioTests/TensioAppSmokeTests.swift
TensioUITests/TensioSmokeUITests.swift
```

- [ ] **Step 8: Add the minimal app shell**

Create `Tensio/App/MainTab.swift`:

```swift
import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case today
    case log
    case medicines
    case report
    case settings

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .log: "Log"
        case .medicines: "Medicines"
        case .report: "Report"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "heart.text.square"
        case .log: "list.bullet.clipboard"
        case .medicines: "pills"
        case .report: "doc.text"
        case .settings: "gearshape"
        }
    }
}
```

Create `Tensio/App/AppRootView.swift`:

```swift
import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    Text(tab.title)
                        .font(.largeTitle.weight(.semibold))
                        .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
            }
        }
    }
}
```

Create `Tensio/App/TensioApp.swift`:

```swift
import SwiftUI

@main
struct TensioApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
```

- [ ] **Step 9: Add app smoke tests**

Create `TensioTests/TensioAppSmokeTests.swift`:

```swift
import XCTest
@testable import Tensio

final class TensioAppSmokeTests: XCTestCase {
    func testAllMainTabsHaveTitlesAndSymbols() {
        for tab in MainTab.allCases {
            XCTAssertFalse(String(localized: tab.title).isEmpty)
            XCTAssertFalse(tab.systemImage.isEmpty)
        }
    }
}
```

Create `TensioUITests/TensioSmokeUITests.swift`:

```swift
import XCTest

final class TensioSmokeUITests: XCTestCase {
    func testLaunchShowsMainTabs() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Log"].exists)
        XCTAssertTrue(app.tabBars.buttons["Medicines"].exists)
        XCTAssertTrue(app.tabBars.buttons["Report"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}
```

- [ ] **Step 10: Add `.gitignore`**

Create `.gitignore`:

```gitignore
.DS_Store
.build/
build/
DerivedData/
screenshots/
*.xcuserstate
xcuserdata/
*.moved-aside
*.xccheckout
*.xcscmblueprint
.claude/
.agents/
skills-lock.json
agents.original.md
```

- [ ] **Step 11: Verify app build and tests**

Use XcodeBuildMCP if defaults can be configured for `Tensio.xcodeproj`, scheme `Tensio`, and an iOS simulator:

```text
Call mcp__XcodeBuildMCP.session_show_defaults
Call mcp__XcodeBuildMCP.test_sim with progress true
```

CLI fallback:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: app target, unit tests, and UI tests pass.

- [ ] **Step 12: Commit**

```bash
git add .gitignore VERSION agents.md support.md privacy-policy.md EULA.md ci_scripts Package.swift Sources Tests Tensio.xcodeproj Tensio TensioTests TensioUITests
git commit -m "chore: scaffold Tensio iOS app"
```

---

### Task 2: Clinical Domain Rules

**Files:**
- Create: `Sources/TensioCore/BloodPressureCategory.swift`
- Create: `Sources/TensioCore/BloodPressureReading.swift`
- Create: `Sources/TensioCore/ClinicalGuidance.swift`
- Create: `Tests/TensioCoreTests/BloodPressureCategoryTests.swift`
- Modify: `Sources/TensioCore/TensioCore.swift`

**Interfaces:**
- Produces: `BloodPressureReading(id:measuredAt:systolic:diastolic:pulse:)`.
- Produces: `BloodPressureCategory.classify(systolic:diastolic:) -> BloodPressureCategory`.
- Produces: `ClinicalGuidance.make(for:hasEmergencySymptoms:) -> ClinicalGuidance`.
- Consumed by: persistence, entry confirmation, dashboard, reports.

- [ ] **Step 1: Write failing category and guidance tests**

Create `Tests/TensioCoreTests/BloodPressureCategoryTests.swift`:

```swift
import XCTest
@testable import TensioCore

final class BloodPressureCategoryTests: XCTestCase {
    func testClassifiesAhaCategories() {
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 118, diastolic: 76), .normal)
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 126, diastolic: 78), .elevated)
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 134, diastolic: 82), .stage1)
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 146, diastolic: 91), .stage2)
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 181, diastolic: 77), .severe)
        XCTAssertEqual(BloodPressureCategory.classify(systolic: 120, diastolic: 121), .severe)
    }

    func testGuidanceForSevereReadingWithoutSymptoms() {
        let reading = BloodPressureReading(
            id: UUID(uuidString: "6C4DBA33-9E8C-4EA0-89C8-503E2225E3C6")!,
            measuredAt: Date(timeIntervalSince1970: 1_800_000_000),
            systolic: 182,
            diastolic: 118,
            pulse: 74
        )

        let guidance = ClinicalGuidance.make(for: reading, hasEmergencySymptoms: false)

        XCTAssertEqual(guidance.category, .severe)
        XCTAssertEqual(guidance.title, "Take another reading")
        XCTAssertEqual(guidance.action, .repeatMeasurement)
        XCTAssertTrue(guidance.body.contains("Wait at least 1 minute"))
    }

    func testGuidanceForSevereReadingWithSymptoms() {
        let reading = BloodPressureReading(
            id: UUID(uuidString: "7D1908F9-F5C4-49E4-A3C4-335EC0D94136")!,
            measuredAt: Date(timeIntervalSince1970: 1_800_000_000),
            systolic: 190,
            diastolic: 125,
            pulse: nil
        )

        let guidance = ClinicalGuidance.make(for: reading, hasEmergencySymptoms: true)

        XCTAssertEqual(guidance.action, .callEmergencyServices)
        XCTAssertEqual(guidance.title, "Call emergency services")
        XCTAssertTrue(guidance.body.contains("chest pain"))
    }

    func testGuidanceDoesNotDiagnose() {
        let reading = BloodPressureReading(
            id: UUID(uuidString: "642AFB02-565A-476D-8E60-06682B558C0B")!,
            measuredAt: Date(timeIntervalSince1970: 1_800_000_000),
            systolic: 136,
            diastolic: 84,
            pulse: nil
        )

        let guidance = ClinicalGuidance.make(for: reading, hasEmergencySymptoms: nil)

        XCTAssertEqual(guidance.category, .stage1)
        XCTAssertTrue(guidance.body.contains("Only a clinician can diagnose"))
        XCTAssertFalse(guidance.body.contains("You have hypertension"))
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter BloodPressureCategoryTests
```

Expected: FAIL because `BloodPressureCategory`, `BloodPressureReading`, and `ClinicalGuidance` do not exist.

- [ ] **Step 3: Implement category and reading types**

Create `Sources/TensioCore/BloodPressureReading.swift`:

```swift
import Foundation

public struct BloodPressureReading: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let measuredAt: Date
    public let systolic: Int
    public let diastolic: Int
    public let pulse: Int?

    public init(id: UUID = UUID(), measuredAt: Date, systolic: Int, diastolic: Int, pulse: Int?) {
        self.id = id
        self.measuredAt = measuredAt
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
    }
}
```

Create `Sources/TensioCore/BloodPressureCategory.swift`:

```swift
public enum BloodPressureCategory: String, CaseIterable, Codable, Equatable, Sendable {
    case normal
    case elevated
    case stage1
    case stage2
    case severe

    public static func classify(systolic: Int, diastolic: Int) -> BloodPressureCategory {
        if systolic > 180 || diastolic > 120 {
            return .severe
        }
        if systolic >= 140 || diastolic >= 90 {
            return .stage2
        }
        if (130...139).contains(systolic) || (80...89).contains(diastolic) {
            return .stage1
        }
        if (120...129).contains(systolic) && diastolic < 80 {
            return .elevated
        }
        return .normal
    }

    public var displayName: String {
        switch self {
        case .normal: "Normal"
        case .elevated: "Elevated"
        case .stage1: "Stage 1"
        case .stage2: "Stage 2"
        case .severe: "Severe"
        }
    }
}
```

- [ ] **Step 4: Implement deterministic guidance**

Create `Sources/TensioCore/ClinicalGuidance.swift`:

```swift
public struct ClinicalGuidance: Equatable, Sendable {
    public enum Action: Equatable, Sendable {
        case trackTrend
        case discussWithClinician
        case repeatMeasurement
        case callEmergencyServices
    }

    public let category: BloodPressureCategory
    public let title: String
    public let body: String
    public let action: Action

    public static func make(for reading: BloodPressureReading, hasEmergencySymptoms: Bool?) -> ClinicalGuidance {
        let category = BloodPressureCategory.classify(systolic: reading.systolic, diastolic: reading.diastolic)

        if category == .severe {
            if hasEmergencySymptoms == true {
                return ClinicalGuidance(
                    category: category,
                    title: "Call emergency services",
                    body: "If this reading is above 180 systolic or above 120 diastolic and you have chest pain, shortness of breath, back pain, numbness, weakness, vision change, or difficulty speaking, call emergency services now.",
                    action: .callEmergencyServices
                )
            }

            return ClinicalGuidance(
                category: category,
                title: "Take another reading",
                body: "Wait at least 1 minute, sit quietly, and take your blood pressure again. If it stays this high, contact your clinician. If you have chest pain, shortness of breath, back pain, numbness, weakness, vision change, or difficulty speaking, call emergency services.",
                action: .repeatMeasurement
            )
        }

        switch category {
        case .normal:
            return ClinicalGuidance(
                category: category,
                title: "In normal range",
                body: "Save this reading and keep tracking your routine. Only a clinician can diagnose or rule out a condition.",
                action: .trackTrend
            )
        case .elevated:
            return ClinicalGuidance(
                category: category,
                title: "Elevated reading",
                body: "Track this trend and discuss your usual range with your clinician. Only a clinician can diagnose high blood pressure.",
                action: .trackTrend
            )
        case .stage1, .stage2:
            return ClinicalGuidance(
                category: category,
                title: "Discuss this trend",
                body: "This reading is above the normal range. Only a clinician can diagnose high blood pressure or recommend treatment changes.",
                action: .discussWithClinician
            )
        case .severe:
            fatalError("Severe guidance is handled before this switch")
        }
    }
}
```

- [ ] **Step 5: Run core tests**

Run:

```bash
swift test --filter BloodPressureCategoryTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/TensioCore Tests/TensioCoreTests
git commit -m "feat: add blood pressure clinical rules"
```

---

### Task 3: SwiftData Models and Repositories

**Files:**
- Create: `Tensio/Persistence/TensioModelContainer.swift`
- Create: `Tensio/Persistence/BPReadingRecord.swift`
- Create: `Tensio/Persistence/MedicationRecord.swift`
- Create: `Tensio/Persistence/DoseLogRecord.swift`
- Create: `Tensio/Persistence/MonitoringSessionRecord.swift`
- Create: `Tensio/Persistence/Repositories.swift`
- Create: `TensioTests/PersistenceTests.swift`
- Modify: `Tensio/App/TensioApp.swift`

**Interfaces:**
- Consumes: `BloodPressureReading` from Task 2.
- Produces: `ReadingRepository`, `MedicationRepository`, `MonitoringSessionRepository`.
- Produces: `TensioModelContainer.make(inMemory:) -> ModelContainer`.
- Consumed by: entry, dashboard, coach, medications, reports, settings.

- [ ] **Step 1: Write failing persistence tests**

Create `TensioTests/PersistenceTests.swift`:

```swift
import XCTest
import SwiftData
import TensioCore
@testable import Tensio

@MainActor
final class PersistenceTests: XCTestCase {
    func testReadingRepositorySavesAndFetchesNewestFirst() throws {
        let container = try TensioModelContainer.make(inMemory: true)
        let repository = ReadingRepository(modelContext: container.mainContext)

        try repository.save(
            BloodPressureReading(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                measuredAt: Date(timeIntervalSince1970: 100),
                systolic: 128,
                diastolic: 78,
                pulse: 70
            ),
            context: ReadingContext(arm: .left, posture: .seated, tags: [.caffeine], note: "after coffee")
        )
        try repository.save(
            BloodPressureReading(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                measuredAt: Date(timeIntervalSince1970: 200),
                systolic: 142,
                diastolic: 90,
                pulse: nil
            ),
            context: ReadingContext(arm: .right, posture: .seated, tags: [.missedMedicine], note: "")
        )

        let readings = try repository.fetchReadings(limit: 10)

        XCTAssertEqual(readings.map(\.systolic), [142, 128])
        XCTAssertEqual(readings.first?.category, .stage2)
        XCTAssertEqual(readings.first?.context.tags, [.missedMedicine])
    }

    func testMedicationRepositoryLogsDose() throws {
        let container = try TensioModelContainer.make(inMemory: true)
        let repository = MedicationRepository(modelContext: container.mainContext)

        let medicationID = try repository.saveMedication(
            MedicationDraft(
                name: "Lisinopril",
                dose: "10 mg",
                schedule: .daily(hour: 8, minute: 0),
                refillDate: Date(timeIntervalSince1970: 1_800_086_400)
            )
        )
        try repository.logDose(
            medicationID: medicationID,
            takenAt: Date(timeIntervalSince1970: 1_800_000_000),
            status: .taken
        )

        let medications = try repository.fetchMedications()

        XCTAssertEqual(medications.count, 1)
        XCTAssertEqual(medications[0].name, "Lisinopril")
        XCTAssertEqual(medications[0].doseLogs.count, 1)
        XCTAssertEqual(medications[0].doseLogs[0].status, .taken)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioTests/PersistenceTests
```

Expected: FAIL because persistence types do not exist.

- [ ] **Step 3: Implement reading models and context types**

Create `Tensio/Persistence/BPReadingRecord.swift` with these public app-target types:

```swift
import Foundation
import SwiftData
import TensioCore

enum ReadingArm: String, Codable, CaseIterable {
    case left
    case right
}

enum ReadingPosture: String, Codable, CaseIterable {
    case seated
    case standing
    case lyingDown
}

enum ReadingTag: String, Codable, CaseIterable, Hashable {
    case symptom
    case stress
    case caffeine
    case exercise
    case missedMedicine
}

struct ReadingContext: Codable, Equatable {
    var arm: ReadingArm?
    var posture: ReadingPosture?
    var tags: [ReadingTag]
    var note: String
}

struct StoredReading: Equatable, Identifiable {
    var id: UUID
    var measuredAt: Date
    var systolic: Int
    var diastolic: Int
    var pulse: Int?
    var category: BloodPressureCategory
    var context: ReadingContext
}

@Model
final class BPReadingRecord {
    var id: UUID
    var measuredAt: Date
    var systolic: Int
    var diastolic: Int
    var pulse: Int?
    var armRaw: String?
    var postureRaw: String?
    var tagRawValues: [String]
    var note: String

    init(id: UUID, measuredAt: Date, systolic: Int, diastolic: Int, pulse: Int?, context: ReadingContext) {
        self.id = id
        self.measuredAt = measuredAt
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
        self.armRaw = context.arm?.rawValue
        self.postureRaw = context.posture?.rawValue
        self.tagRawValues = context.tags.map(\.rawValue)
        self.note = context.note
    }

    var storedReading: StoredReading {
        let context = ReadingContext(
            arm: armRaw.flatMap(ReadingArm.init(rawValue:)),
            posture: postureRaw.flatMap(ReadingPosture.init(rawValue:)),
            tags: tagRawValues.compactMap(ReadingTag.init(rawValue:)),
            note: note
        )

        return StoredReading(
            id: id,
            measuredAt: measuredAt,
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            category: BloodPressureCategory.classify(systolic: systolic, diastolic: diastolic),
            context: context
        )
    }
}
```

- [ ] **Step 4: Implement medication and session models**

Create `Tensio/Persistence/MedicationRecord.swift`:

```swift
import Foundation
import SwiftData

enum MedicationSchedule: Codable, Equatable {
    case daily(hour: Int, minute: Int)
}

struct MedicationDraft: Equatable {
    var name: String
    var dose: String
    var schedule: MedicationSchedule
    var refillDate: Date?
}

struct StoredMedication: Equatable, Identifiable {
    var id: UUID
    var name: String
    var dose: String
    var schedule: MedicationSchedule
    var refillDate: Date?
    var doseLogs: [StoredDoseLog]
}

@Model
final class MedicationRecord {
    var id: UUID
    var name: String
    var dose: String
    var scheduleHour: Int
    var scheduleMinute: Int
    var refillDate: Date?
    @Relationship(deleteRule: .cascade, inverse: \DoseLogRecord.medication) var doseLogs: [DoseLogRecord]

    init(id: UUID = UUID(), name: String, dose: String, scheduleHour: Int, scheduleMinute: Int, refillDate: Date?) {
        self.id = id
        self.name = name
        self.dose = dose
        self.scheduleHour = scheduleHour
        self.scheduleMinute = scheduleMinute
        self.refillDate = refillDate
        self.doseLogs = []
    }

    var storedMedication: StoredMedication {
        StoredMedication(
            id: id,
            name: name,
            dose: dose,
            schedule: .daily(hour: scheduleHour, minute: scheduleMinute),
            refillDate: refillDate,
            doseLogs: doseLogs.sorted { $0.takenAt > $1.takenAt }.map(\.storedDoseLog)
        )
    }
}
```

Create `Tensio/Persistence/DoseLogRecord.swift`:

```swift
import Foundation
import SwiftData

enum DoseStatus: String, Codable, Equatable {
    case taken
    case late
    case skipped
}

struct StoredDoseLog: Equatable, Identifiable {
    var id: UUID
    var takenAt: Date
    var status: DoseStatus
}

@Model
final class DoseLogRecord {
    var id: UUID
    var takenAt: Date
    var statusRaw: String
    var medication: MedicationRecord?

    init(id: UUID = UUID(), takenAt: Date, status: DoseStatus, medication: MedicationRecord) {
        self.id = id
        self.takenAt = takenAt
        self.statusRaw = status.rawValue
        self.medication = medication
    }

    var storedDoseLog: StoredDoseLog {
        StoredDoseLog(
            id: id,
            takenAt: takenAt,
            status: DoseStatus(rawValue: statusRaw) ?? .taken
        )
    }
}
```

Create `Tensio/Persistence/MonitoringSessionRecord.swift`:

```swift
import Foundation
import SwiftData

@Model
final class MonitoringSessionRecord {
    var id: UUID
    var startedAt: Date
    var targetDays: Int
    var isActive: Bool

    init(id: UUID = UUID(), startedAt: Date, targetDays: Int = 7, isActive: Bool = true) {
        self.id = id
        self.startedAt = startedAt
        self.targetDays = targetDays
        self.isActive = isActive
    }
}
```

- [ ] **Step 5: Implement model container and repositories**

Create `Tensio/Persistence/TensioModelContainer.swift`:

```swift
import SwiftData

enum TensioModelContainer {
    @MainActor
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            BPReadingRecord.self,
            MedicationRecord.self,
            DoseLogRecord.self,
            MonitoringSessionRecord.self
        ])
        let configuration = ModelConfiguration("local", schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
```

Create `Tensio/Persistence/Repositories.swift`:

```swift
import Foundation
import SwiftData
import TensioCore

@MainActor
final class ReadingRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ reading: BloodPressureReading, context: ReadingContext) throws {
        modelContext.insert(
            BPReadingRecord(
                id: reading.id,
                measuredAt: reading.measuredAt,
                systolic: reading.systolic,
                diastolic: reading.diastolic,
                pulse: reading.pulse,
                context: context
            )
        )
        try modelContext.save()
    }

    func fetchReadings(limit: Int) throws -> [StoredReading] {
        var descriptor = FetchDescriptor<BPReadingRecord>(
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map(\.storedReading)
    }
}

@MainActor
final class MedicationRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveMedication(_ draft: MedicationDraft) throws -> UUID {
        let hour: Int
        let minute: Int
        switch draft.schedule {
        case let .daily(scheduleHour, scheduleMinute):
            hour = scheduleHour
            minute = scheduleMinute
        }

        let record = MedicationRecord(
            name: draft.name,
            dose: draft.dose,
            scheduleHour: hour,
            scheduleMinute: minute,
            refillDate: draft.refillDate
        )
        modelContext.insert(record)
        try modelContext.save()
        return record.id
    }

    func logDose(medicationID: UUID, takenAt: Date, status: DoseStatus) throws {
        let descriptor = FetchDescriptor<MedicationRecord>(
            predicate: #Predicate { $0.id == medicationID }
        )
        guard let medication = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.insert(DoseLogRecord(takenAt: takenAt, status: status, medication: medication))
        try modelContext.save()
    }

    func fetchMedications() throws -> [StoredMedication] {
        let descriptor = FetchDescriptor<MedicationRecord>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor).map(\.storedMedication)
    }
}

enum RepositoryError: Error, Equatable {
    case notFound
}
```

- [ ] **Step 6: Wire the model container into the app**

Modify `Tensio/App/TensioApp.swift`:

```swift
import SwiftData
import SwiftUI

@main
struct TensioApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try TensioModelContainer.make()
        } catch {
            fatalError("Unable to create Tensio model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
```

- [ ] **Step 7: Run persistence tests**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioTests/PersistenceTests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Tensio/Persistence Tensio/App/TensioApp.swift TensioTests/PersistenceTests.swift
git commit -m "feat: add local persistence layer"
```

---

### Task 4: Premium Senior-Friendly App Shell and Design System

**Files:**
- Create: `Tensio/Design/TensioTheme.swift`
- Create: `Tensio/Design/TensioComponents.swift`
- Modify: `Tensio/App/AppRootView.swift`
- Create: `TensioUITests/SeniorAccessibilityUITests.swift`

**Interfaces:**
- Produces: `TensioTheme`, `ReadingStatusStyle`, `PrimaryActionButton`, `SecondaryActionButton`, `ClinicSlipSurface`.
- Consumed by: all feature views.

- [ ] **Step 1: Write failing accessibility smoke tests**

Create `TensioUITests/SeniorAccessibilityUITests.swift`:

```swift
import XCTest

final class SeniorAccessibilityUITests: XCTestCase {
    func testPrimaryTabsRemainVisibleWithLargeContentSize() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Log"].exists)
        XCTAssertTrue(app.tabBars.buttons["Medicines"].exists)
        XCTAssertTrue(app.tabBars.buttons["Report"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}
```

- [ ] **Step 2: Run UI test to capture current baseline**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/SeniorAccessibilityUITests
```

Expected: PASS with all five tab labels visible. If it fails because Dynamic Type hides or clips a tab label, this task must fix that layout before commit.

- [ ] **Step 3: Add theme tokens**

Create `Tensio/Design/TensioTheme.swift`:

```swift
import SwiftUI

enum TensioTheme {
    enum ColorToken {
        static let porcelain = Color(red: 0.969, green: 0.965, blue: 0.949)
        static let ink = Color(red: 0.118, green: 0.137, blue: 0.125)
        static let evergreen = Color(red: 0.090, green: 0.231, blue: 0.208)
        static let warmGraphite = Color(red: 0.302, green: 0.337, blue: 0.318)
        static let clinicalBlue = Color(red: 0.184, green: 0.435, blue: 0.733)
        static let brass = Color(red: 0.725, green: 0.580, blue: 0.322)
        static let mist = Color(red: 0.906, green: 0.925, blue: 0.910)
        static let signalRed = Color(red: 0.722, green: 0.227, blue: 0.227)
    }

    enum Spacing {
        static let screen: CGFloat = 20
        static let section: CGFloat = 24
        static let controlHeight: CGFloat = 56
        static let radius: CGFloat = 8
    }

    static func readingFont(_ size: CGFloat = 64) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}
```

- [ ] **Step 4: Add reusable components**

Create `Tensio/Design/TensioComponents.swift`:

```swift
import SwiftUI
import TensioCore

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
        }
        .buttonStyle(.borderedProminent)
        .tint(TensioTheme.ColorToken.evergreen)
        .accessibilityHint(Text("Activates \(title)"))
    }
}

struct SecondaryActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
        }
        .buttonStyle(.bordered)
        .tint(TensioTheme.ColorToken.evergreen)
    }
}

struct ClinicSlipSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Rectangle()
                .fill(TensioTheme.ColorToken.brass)
                .frame(height: 2)
                .accessibilityHidden(true)
            content
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: TensioTheme.Spacing.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: TensioTheme.Spacing.radius, style: .continuous)
                .stroke(TensioTheme.ColorToken.mist, lineWidth: 1)
        }
    }
}

struct ReadingStatusStyle {
    let foreground: Color
    let label: String

    static func style(for category: BloodPressureCategory) -> ReadingStatusStyle {
        switch category {
        case .normal:
            ReadingStatusStyle(foreground: TensioTheme.ColorToken.evergreen, label: "Normal")
        case .elevated:
            ReadingStatusStyle(foreground: TensioTheme.ColorToken.brass, label: "Elevated")
        case .stage1:
            ReadingStatusStyle(foreground: TensioTheme.ColorToken.clinicalBlue, label: "Stage 1")
        case .stage2:
            ReadingStatusStyle(foreground: TensioTheme.ColorToken.clinicalBlue, label: "Stage 2")
        case .severe:
            ReadingStatusStyle(foreground: TensioTheme.ColorToken.signalRed, label: "Severe")
        }
    }
}
```

- [ ] **Step 5: Apply app background and tint**

Modify `Tensio/App/AppRootView.swift` so the tab view is tinted and each placeholder screen uses the porcelain background:

```swift
import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    ZStack {
                        TensioTheme.ColorToken.porcelain
                            .ignoresSafeArea()
                        Text(tab.title)
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(TensioTheme.ColorToken.ink)
                    }
                    .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
            }
        }
        .tint(TensioTheme.ColorToken.evergreen)
    }
}
```

- [ ] **Step 6: Run app UI tests**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/SeniorAccessibilityUITests
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Tensio/Design Tensio/App/AppRootView.swift TensioUITests/SeniorAccessibilityUITests.swift
git commit -m "feat: add senior-friendly design system"
```

---

### Task 5: Onboarding and Measurement Technique Coach

**Files:**
- Create: `Tensio/Features/Onboarding/OnboardingView.swift`
- Create: `Tensio/Features/Onboarding/MeasurementTechniqueView.swift`
- Create: `Sources/TensioCore/MonitoringProtocol.swift`
- Create: `Tests/TensioCoreTests/MonitoringProtocolTests.swift`
- Modify: `Tensio/App/AppRootView.swift`

**Interfaces:**
- Produces: `MonitoringProtocol.requiredSessions(starting:) -> [MonitoringSessionSlot]`.
- Produces: `MeasurementTechniqueView`.
- Consumed by: coach, reports, onboarding.

- [ ] **Step 1: Write failing protocol tests**

Create `Tests/TensioCoreTests/MonitoringProtocolTests.swift`:

```swift
import XCTest
@testable import TensioCore

final class MonitoringProtocolTests: XCTestCase {
    func testSevenDayProtocolCreatesMorningAndEveningSlots() {
        let calendar = Calendar(identifier: .gregorian)
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        let slots = MonitoringProtocol.requiredSessions(starting: start, calendar: calendar)

        XCTAssertEqual(slots.count, 14)
        XCTAssertEqual(slots.first?.dayIndex, 1)
        XCTAssertEqual(slots.first?.period, .morning)
        XCTAssertEqual(slots.last?.dayIndex, 7)
        XCTAssertEqual(slots.last?.period, .evening)
    }

    func testDiagnosticAverageExcludesDayOne() {
        let readings = [
            ProtocolReading(dayIndex: 1, systolic: 180, diastolic: 110),
            ProtocolReading(dayIndex: 2, systolic: 130, diastolic: 82),
            ProtocolReading(dayIndex: 2, systolic: 128, diastolic: 80),
            ProtocolReading(dayIndex: 3, systolic: 126, diastolic: 78)
        ]

        let average = MonitoringProtocol.averageForReport(readings)

        XCTAssertEqual(average?.systolic, 128)
        XCTAssertEqual(average?.diastolic, 80)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter MonitoringProtocolTests
```

Expected: FAIL because monitoring protocol types do not exist.

- [ ] **Step 3: Implement protocol model**

Create `Sources/TensioCore/MonitoringProtocol.swift`:

```swift
import Foundation

public enum MonitoringPeriod: String, Codable, Equatable, Sendable {
    case morning
    case evening
}

public struct MonitoringSessionSlot: Codable, Equatable, Sendable {
    public let dayIndex: Int
    public let period: MonitoringPeriod
    public let date: Date
}

public struct ProtocolReading: Codable, Equatable, Sendable {
    public let dayIndex: Int
    public let systolic: Int
    public let diastolic: Int

    public init(dayIndex: Int, systolic: Int, diastolic: Int) {
        self.dayIndex = dayIndex
        self.systolic = systolic
        self.diastolic = diastolic
    }
}

public struct ProtocolAverage: Codable, Equatable, Sendable {
    public let systolic: Int
    public let diastolic: Int
}

public enum MonitoringProtocol {
    public static func requiredSessions(starting start: Date, calendar: Calendar = .current) -> [MonitoringSessionSlot] {
        (0..<7).flatMap { offset -> [MonitoringSessionSlot] in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return [
                MonitoringSessionSlot(dayIndex: offset + 1, period: .morning, date: date),
                MonitoringSessionSlot(dayIndex: offset + 1, period: .evening, date: date)
            ]
        }
    }

    public static func averageForReport(_ readings: [ProtocolReading]) -> ProtocolAverage? {
        let included = readings.filter { $0.dayIndex > 1 }
        guard !included.isEmpty else { return nil }
        let systolic = included.map(\.systolic).reduce(0, +) / included.count
        let diastolic = included.map(\.diastolic).reduce(0, +) / included.count
        return ProtocolAverage(systolic: systolic, diastolic: diastolic)
    }
}
```

- [ ] **Step 4: Add onboarding and technique views**

Create `Tensio/Features/Onboarding/MeasurementTechniqueView.swift`:

```swift
import SwiftUI

struct MeasurementTechniqueView: View {
    private let items: [(String, String)] = [
        ("Rest first", "Sit quietly for 5 minutes before measuring."),
        ("Use bare skin", "Place the cuff on your arm, not over clothing."),
        ("Support your arm", "Keep the cuff at heart level."),
        ("Stay still", "Keep both feet flat and avoid talking."),
        ("Take two readings", "Wait at least 1 minute before the second reading.")
    ]

    var body: some View {
        List(items, id: \.0) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.0)
                    .font(.headline)
                Text(item.1)
                    .font(.body)
                    .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Measure well")
    }
}
```

Create `Tensio/Features/Onboarding/OnboardingView.swift`:

```swift
import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationStack {
            ZStack {
                TensioTheme.ColorToken.porcelain.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 24) {
                    ClinicSlipSurface {
                        Text("Tensio")
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                        Text("A calm place to save blood pressure readings and bring useful summaries to your clinician.")
                            .font(.title3)
                            .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
                    }

                    NavigationLink {
                        MeasurementTechniqueView()
                    } label: {
                        Label("Review measuring steps", systemImage: "checklist")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
                    }
                    .buttonStyle(.bordered)

                    PrimaryActionButton(title: "Start using Tensio", systemImage: "heart.text.square") {
                        hasCompletedOnboarding = true
                    }
                }
                .padding(TensioTheme.Spacing.screen)
            }
            .navigationTitle("Welcome")
        }
    }
}
```

- [ ] **Step 5: Gate the root view with onboarding**

Modify `Tensio/App/AppRootView.swift`:

```swift
import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            mainTabs
        } else {
            OnboardingView()
        }
    }

    private var mainTabs: some View {
        TabView {
            ForEach(MainTab.allCases) { tab in
                NavigationStack {
                    ZStack {
                        TensioTheme.ColorToken.porcelain
                            .ignoresSafeArea()
                        Text(tab.title)
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(TensioTheme.ColorToken.ink)
                    }
                    .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
            }
        }
        .tint(TensioTheme.ColorToken.evergreen)
    }
}
```

- [ ] **Step 6: Run tests**

Run:

```bash
swift test --filter MonitoringProtocolTests
```

Expected: PASS.

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS. If the UI smoke test starts on onboarding, update only the UI test launch arguments to set `hasCompletedOnboarding` through `UserDefaults` before launch.

- [ ] **Step 7: Commit**

```bash
git add Sources/TensioCore Tests/TensioCoreTests Tensio/Features/Onboarding Tensio/App/AppRootView.swift TensioUITests
git commit -m "feat: add onboarding and measurement coach"
```

---

### Task 6: Ultra-Fast Manual Reading Entry

**Files:**
- Create: `Tensio/Features/Entry/LargeNumberPad.swift`
- Create: `Tensio/Features/Entry/ReadingContextView.swift`
- Create: `Tensio/Features/Entry/ReadingEntryView.swift`
- Modify: `Tensio/App/AppRootView.swift`
- Create: `TensioUITests/ReadingEntryUITests.swift`

**Interfaces:**
- Consumes: `ReadingRepository.save(_:context:)`.
- Consumes: `ClinicalGuidance.make(for:hasEmergencySymptoms:)`.
- Produces: manual entry flow and severe reading prompt.
- Consumed by: Today view and tab shell.

- [ ] **Step 1: Write failing UI entry test**

Create `TensioUITests/ReadingEntryUITests.swift`:

```swift
import XCTest

final class ReadingEntryUITests: XCTestCase {
    func testManualReadingCanBeSavedFromToday() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--onboarding-complete"]
        app.launch()

        XCTAssertTrue(app.buttons["Add reading"].waitForExistence(timeout: 5))
        app.buttons["Add reading"].tap()

        app.textFields["Systolic"].tap()
        app.textFields["Systolic"].typeText("128")
        app.textFields["Diastolic"].tap()
        app.textFields["Diastolic"].typeText("78")
        app.textFields["Pulse"].tap()
        app.textFields["Pulse"].typeText("70")

        app.buttons["Save reading"].tap()

        XCTAssertTrue(app.staticTexts["Elevated"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/ReadingEntryUITests
```

Expected: FAIL because `Add reading` does not exist.

- [ ] **Step 3: Add the number pad helper**

Create `Tensio/Features/Entry/LargeNumberPad.swift`:

```swift
import SwiftUI

struct LargeNumberField: View {
    let title: LocalizedStringKey
    let accessibilityIdentifier: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            TextField(title, text: $value)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .frame(minHeight: 64)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
    }
}
```

- [ ] **Step 4: Add context chips**

Create `Tensio/Features/Entry/ReadingContextView.swift`:

```swift
import SwiftUI

struct ReadingContextView: View {
    @Binding var context: ReadingContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Arm", selection: Binding(
                get: { context.arm ?? .left },
                set: { context.arm = $0 }
            )) {
                Text("Left").tag(ReadingArm.left)
                Text("Right").tag(ReadingArm.right)
            }
            .pickerStyle(.segmented)

            Picker("Posture", selection: Binding(
                get: { context.posture ?? .seated },
                set: { context.posture = $0 }
            )) {
                Text("Seated").tag(ReadingPosture.seated)
                Text("Standing").tag(ReadingPosture.standing)
                Text("Lying").tag(ReadingPosture.lyingDown)
            }
            .pickerStyle(.segmented)

            FlowChipGroup(selectedTags: $context.tags)

            TextField("Note", text: $context.note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }
}

private struct FlowChipGroup: View {
    @Binding var selectedTags: [ReadingTag]

    var body: some View {
        let tags = ReadingTag.allCases
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Toggle(tag.label, isOn: Binding(
                    get: { selectedTags.contains(tag) },
                    set: { isSelected in
                        if isSelected {
                            selectedTags.append(tag)
                        } else {
                            selectedTags.removeAll { $0 == tag }
                        }
                    }
                ))
                .toggleStyle(.button)
                .frame(minHeight: 44)
            }
        }
    }
}

private extension ReadingTag {
    var label: String {
        switch self {
        case .symptom: "Symptom"
        case .stress: "Stress"
        case .caffeine: "Caffeine"
        case .exercise: "Exercise"
        case .missedMedicine: "Missed medicine"
        }
    }
}
```

- [ ] **Step 5: Add reading entry view**

Create `Tensio/Features/Entry/ReadingEntryView.swift`:

```swift
import SwiftData
import SwiftUI
import TensioCore

struct ReadingEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var pulse = ""
    @State private var context = ReadingContext(arm: .left, posture: .seated, tags: [], note: "")
    @State private var guidance: ClinicalGuidance?
    @State private var showingSevereSymptomsPrompt = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ClinicSlipSurface {
                        LargeNumberField(title: "Systolic", accessibilityIdentifier: "Systolic", value: $systolic)
                        LargeNumberField(title: "Diastolic", accessibilityIdentifier: "Diastolic", value: $diastolic)
                        LargeNumberField(title: "Pulse", accessibilityIdentifier: "Pulse", value: $pulse)
                    }

                    ReadingContextView(context: $context)

                    if let guidance {
                        GuidanceBanner(guidance: guidance)
                    }

                    PrimaryActionButton(title: "Save reading", systemImage: "checkmark") {
                        saveReading()
                    }
                    .disabled(!canSave)
                }
                .padding(TensioTheme.Spacing.screen)
            }
            .background(TensioTheme.ColorToken.porcelain)
            .navigationTitle("Add reading")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Any emergency symptoms?",
                isPresented: $showingSevereSymptomsPrompt,
                titleVisibility: .visible
            ) {
                Button("Yes, show emergency guidance", role: .destructive) {
                    updateGuidance(hasEmergencySymptoms: true)
                }
                Button("No symptoms") {
                    updateGuidance(hasEmergencySymptoms: false)
                    persistReading()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Chest pain, shortness of breath, back pain, numbness, weakness, vision change, or difficulty speaking.")
            }
        }
    }

    private var canSave: Bool {
        Int(systolic) != nil && Int(diastolic) != nil
    }

    private func saveReading() {
        guard let sys = Int(systolic), let dia = Int(diastolic) else { return }
        let category = BloodPressureCategory.classify(systolic: sys, diastolic: dia)
        if category == .severe {
            showingSevereSymptomsPrompt = true
        } else {
            updateGuidance(hasEmergencySymptoms: nil)
            persistReading()
        }
    }

    private func updateGuidance(hasEmergencySymptoms: Bool?) {
        guard let sys = Int(systolic), let dia = Int(diastolic) else { return }
        let reading = BloodPressureReading(
            measuredAt: Date(),
            systolic: sys,
            diastolic: dia,
            pulse: Int(pulse)
        )
        guidance = ClinicalGuidance.make(for: reading, hasEmergencySymptoms: hasEmergencySymptoms)
    }

    private func persistReading() {
        guard let sys = Int(systolic), let dia = Int(diastolic) else { return }
        let reading = BloodPressureReading(
            measuredAt: Date(),
            systolic: sys,
            diastolic: dia,
            pulse: Int(pulse)
        )
        do {
            try ReadingRepository(modelContext: modelContext).save(reading, context: context)
            dismiss()
        } catch {
            guidance = ClinicalGuidance(
                category: .stage2,
                title: "Reading was not saved",
                body: "Try saving again. Your existing readings are unchanged.",
                action: .trackTrend
            )
        }
    }
}

private struct GuidanceBanner: View {
    let guidance: ClinicalGuidance

    var body: some View {
        let style = ReadingStatusStyle.style(for: guidance.category)
        VStack(alignment: .leading, spacing: 8) {
            Text(guidance.title)
                .font(.headline)
            Text(guidance.body)
                .font(.body)
        }
        .foregroundStyle(style.foreground)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.foreground.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: TensioTheme.Spacing.radius, style: .continuous))
    }
}
```

- [ ] **Step 6: Add the entry button to Today placeholder**

Modify the Today tab in `Tensio/App/AppRootView.swift` so only `.today` shows a button:

```swift
@ViewBuilder
private func content(for tab: MainTab) -> some View {
    switch tab {
    case .today:
        VStack(spacing: 24) {
            Text("Today")
                .font(.largeTitle.weight(.semibold))
            PrimaryActionButton(title: "Add reading", systemImage: "plus") {
                showingEntry = true
            }
        }
        .padding(TensioTheme.Spacing.screen)
    default:
        Text(tab.title)
            .font(.largeTitle.weight(.semibold))
            .foregroundStyle(TensioTheme.ColorToken.ink)
    }
}
```

Add this state to `AppRootView`:

```swift
@State private var showingEntry = false
```

Add this sheet to `mainTabs`:

```swift
.sheet(isPresented: $showingEntry) {
    ReadingEntryView()
}
```

Add this test-mode hook at the start of `body`:

```swift
let arguments = ProcessInfo.processInfo.arguments
if arguments.contains("--onboarding-complete") {
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
}
```

- [ ] **Step 7: Run entry UI test**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/ReadingEntryUITests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Tensio/Features/Entry Tensio/App/AppRootView.swift TensioUITests/ReadingEntryUITests.swift
git commit -m "feat: add fast manual reading entry"
```

---

### Task 7: Today Dashboard, Log, and Trend Chart

**Files:**
- Create: `Tensio/Features/Dashboard/ReadingSlipView.swift`
- Create: `Tensio/Features/Dashboard/TrendChartView.swift`
- Create: `Tensio/Features/Dashboard/TodayView.swift`
- Create: `Tensio/Features/Dashboard/ReadingLogView.swift`
- Modify: `Tensio/App/AppRootView.swift`
- Create: `TensioUITests/DashboardUITests.swift`

**Interfaces:**
- Consumes: `ReadingRepository.fetchReadings(limit:)`.
- Produces: Today and Log tabs.
- Consumed by: Reports through shared visual language only.

- [ ] **Step 1: Write failing dashboard UI test**

Create `TensioUITests/DashboardUITests.swift`:

```swift
import XCTest

final class DashboardUITests: XCTestCase {
    func testTodayShowsEmptyStateAndAddReadingButton() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--onboarding-complete", "--empty-store"]
        app.launch()

        XCTAssertTrue(app.staticTexts["No readings yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add reading"].exists)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/DashboardUITests
```

Expected: FAIL because the empty state does not exist.

- [ ] **Step 3: Add reading slip view**

Create `Tensio/Features/Dashboard/ReadingSlipView.swift`:

```swift
import SwiftUI

struct ReadingSlipView: View {
    let reading: StoredReading

    var body: some View {
        let style = ReadingStatusStyle.style(for: reading.category)
        ClinicSlipSurface {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(reading.systolic)")
                    .font(TensioTheme.readingFont())
                Text("/")
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                Text("\(reading.diastolic)")
                    .font(TensioTheme.readingFont())
            }
            .foregroundStyle(TensioTheme.ColorToken.ink)
            .accessibilityLabel("Blood pressure \(reading.systolic) over \(reading.diastolic)")

            HStack {
                Text(style.label)
                    .font(.headline)
                    .foregroundStyle(style.foreground)
                Spacer()
                if let pulse = reading.pulse {
                    Text("Pulse \(pulse)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Add trend chart**

Create `Tensio/Features/Dashboard/TrendChartView.swift`:

```swift
import Charts
import SwiftUI

struct TrendChartView: View {
    let readings: [StoredReading]

    var body: some View {
        Chart(readings) { reading in
            LineMark(
                x: .value("Date", reading.measuredAt),
                y: .value("Systolic", reading.systolic)
            )
            .foregroundStyle(TensioTheme.ColorToken.clinicalBlue)

            LineMark(
                x: .value("Date", reading.measuredAt),
                y: .value("Diastolic", reading.diastolic)
            )
            .foregroundStyle(TensioTheme.ColorToken.evergreen)
        }
        .frame(height: 220)
        .chartLegend(.visible)
        .accessibilityLabel("Blood pressure trend chart")
    }
}
```

- [ ] **Step 5: Add Today and Log views**

Create `Tensio/Features/Dashboard/TodayView.swift`:

```swift
import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    let onAddReading: () -> Void
    @State private var readings: [StoredReading] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let latest = readings.first {
                    ReadingSlipView(reading: latest)
                    if readings.count >= 2 {
                        TrendChartView(readings: Array(readings.prefix(14)).reversed())
                    }
                } else {
                    ClinicSlipSurface {
                        Text("No readings yet")
                            .font(.title2.weight(.semibold))
                        Text("Add your first reading from your home blood pressure monitor.")
                            .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
                    }
                }

                PrimaryActionButton(title: "Add reading", systemImage: "plus", action: onAddReading)
            }
            .padding(TensioTheme.Spacing.screen)
        }
        .background(TensioTheme.ColorToken.porcelain)
        .navigationTitle("Today")
        .task { loadReadings() }
    }

    private func loadReadings() {
        readings = (try? ReadingRepository(modelContext: modelContext).fetchReadings(limit: 30)) ?? []
    }
}
```

Create `Tensio/Features/Dashboard/ReadingLogView.swift`:

```swift
import SwiftData
import SwiftUI

struct ReadingLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var readings: [StoredReading] = []

    var body: some View {
        List(readings) { reading in
            VStack(alignment: .leading, spacing: 6) {
                Text("\(reading.systolic)/\(reading.diastolic)")
                    .font(.title2.monospacedDigit().weight(.semibold))
                Text(ReadingStatusStyle.style(for: reading.category).label)
                    .font(.subheadline)
                    .foregroundStyle(ReadingStatusStyle.style(for: reading.category).foreground)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Log")
        .task {
            readings = (try? ReadingRepository(modelContext: modelContext).fetchReadings(limit: 500)) ?? []
        }
    }
}
```

- [ ] **Step 6: Wire tabs to dashboard views**

Modify `Tensio/App/AppRootView.swift` so `.today` uses `TodayView(onAddReading:)` and `.log` uses `ReadingLogView()`:

```swift
@ViewBuilder
private func content(for tab: MainTab) -> some View {
    switch tab {
    case .today:
        TodayView(onAddReading: { showingEntry = true })
    case .log:
        ReadingLogView()
    default:
        ZStack {
            TensioTheme.ColorToken.porcelain.ignoresSafeArea()
            Text(tab.title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(TensioTheme.ColorToken.ink)
        }
    }
}
```

- [ ] **Step 7: Run dashboard UI test**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/DashboardUITests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Tensio/Features/Dashboard Tensio/App/AppRootView.swift TensioUITests/DashboardUITests.swift
git commit -m "feat: add dashboard and reading log"
```

---

### Task 8: Monitoring Plan and Local Reminders

**Files:**
- Create: `Tensio/Features/Coach/MeasurementTimerView.swift`
- Create: `Tensio/Features/Coach/ReminderScheduler.swift`
- Create: `Tensio/Features/Coach/MonitoringPlanView.swift`
- Create: `TensioTests/ReminderSchedulerTests.swift`
- Modify: `Tensio/App/AppRootView.swift`

**Interfaces:**
- Consumes: `MonitoringProtocol.requiredSessions`.
- Produces: `ReminderScheduler.scheduleMonitoringPlan(starting:)`.
- Produces: coach UI reachable from Today.

- [ ] **Step 1: Write failing reminder scheduler test**

Create `TensioTests/ReminderSchedulerTests.swift`:

```swift
import XCTest
@testable import Tensio

final class ReminderSchedulerTests: XCTestCase {
    func testMonitoringPlanCreatesFourteenRequests() async throws {
        let center = FakeNotificationCenter()
        let scheduler = ReminderScheduler(notificationCenter: center)

        try await scheduler.scheduleMonitoringPlan(starting: Date(timeIntervalSince1970: 1_800_000_000))

        XCTAssertEqual(center.requests.count, 14)
        XCTAssertTrue(center.requests[0].content.title.contains("Morning blood pressure"))
        XCTAssertTrue(center.requests[1].content.title.contains("Evening blood pressure"))
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioTests/ReminderSchedulerTests
```

Expected: FAIL because `ReminderScheduler` and `FakeNotificationCenter` do not exist.

- [ ] **Step 3: Implement reminder scheduler with injectable center**

Create `Tensio/Features/Coach/ReminderScheduler.swift`:

```swift
import Foundation
import UserNotifications
import TensioCore

protocol NotificationScheduling {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationScheduling {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await requestAuthorization(options: options)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await add(request)
    }
}

final class ReminderScheduler {
    private let notificationCenter: NotificationScheduling

    init(notificationCenter: NotificationScheduling = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

    func scheduleMonitoringPlan(starting start: Date) async throws {
        _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        let slots = MonitoringProtocol.requiredSessions(starting: start)

        for slot in slots {
            let content = UNMutableNotificationContent()
            content.title = slot.period == .morning ? "Morning blood pressure" : "Evening blood pressure"
            content.body = "Sit quietly, take two readings 1 minute apart, then save them in Tensio."
            content.sound = .default

            let date = Calendar.current.dateComponents([.year, .month, .day], from: slot.date)
            var components = date
            components.hour = slot.period == .morning ? 8 : 20
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "monitoring-\(slot.dayIndex)-\(slot.period.rawValue)",
                content: content,
                trigger: trigger
            )
            try await notificationCenter.add(request)
        }
    }
}

#if DEBUG
final class FakeNotificationCenter: NotificationScheduling {
    private(set) var requests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        requests.append(request)
    }
}
#endif
```

- [ ] **Step 4: Add coach views**

Create `Tensio/Features/Coach/MeasurementTimerView.swift`:

```swift
import SwiftUI

struct MeasurementTimerView: View {
    @State private var remaining = 60

    var body: some View {
        VStack(spacing: 24) {
            Text("\(remaining)")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text("Wait at least 1 minute before the second reading.")
                .font(.title3)
                .multilineTextAlignment(.center)
        }
        .padding(TensioTheme.Spacing.screen)
        .task {
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
            }
        }
        .navigationTitle("Second reading")
    }
}
```

Create `Tensio/Features/Coach/MonitoringPlanView.swift`:

```swift
import SwiftUI

struct MonitoringPlanView: View {
    @State private var message = "Start a 7-day plan with morning and evening reminders."

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ClinicSlipSurface {
                Text("7-day monitoring plan")
                    .font(.title2.weight(.semibold))
                Text(message)
                    .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
            }

            NavigationLink {
                MeasurementTimerView()
            } label: {
                Label("Start 1-minute timer", systemImage: "timer")
                    .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
            }
            .buttonStyle(.bordered)

            PrimaryActionButton(title: "Turn on reminders", systemImage: "bell") {
                Task {
                    do {
                        try await ReminderScheduler().scheduleMonitoringPlan(starting: Date())
                        message = "Reminders are set for 7 days."
                    } catch {
                        message = "Reminders were not set. Check notification permission in Settings."
                    }
                }
            }
        }
        .padding(TensioTheme.Spacing.screen)
        .background(TensioTheme.ColorToken.porcelain)
        .navigationTitle("Monitoring plan")
    }
}
```

- [ ] **Step 5: Link coach from Today**

Add a secondary action in `TodayView` below `Add reading`:

```swift
NavigationLink {
    MonitoringPlanView()
} label: {
    Label("7-day plan", systemImage: "calendar.badge.clock")
        .font(.headline)
        .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
}
.buttonStyle(.bordered)
.tint(TensioTheme.ColorToken.evergreen)
```

- [ ] **Step 6: Run scheduler test and app tests**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioTests/ReminderSchedulerTests
```

Expected: PASS.

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Tensio/Features/Coach Tensio/Features/Dashboard/TodayView.swift TensioTests/ReminderSchedulerTests.swift
git commit -m "feat: add monitoring plan reminders"
```

---

### Task 9: Medication Center

**Files:**
- Create: `Tensio/Features/Medications/MedicationCenterView.swift`
- Create: `Tensio/Features/Medications/MedicationEditorView.swift`
- Create: `Tensio/Features/Medications/DoseRowView.swift`
- Modify: `Tensio/App/AppRootView.swift`
- Create: `TensioUITests/MedicationCenterUITests.swift`

**Interfaces:**
- Consumes: `MedicationRepository`.
- Produces: Medicines tab.
- Consumed by: reports through repository reads.

- [ ] **Step 1: Write failing medication UI test**

Create `TensioUITests/MedicationCenterUITests.swift`:

```swift
import XCTest

final class MedicationCenterUITests: XCTestCase {
    func testMedicationCenterShowsAddMedicineAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--onboarding-complete", "--empty-store"]
        app.launch()

        app.tabBars.buttons["Medicines"].tap()

        XCTAssertTrue(app.staticTexts["No medicines yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add medicine"].exists)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/MedicationCenterUITests
```

Expected: FAIL because the Medicines tab is still a placeholder.

- [ ] **Step 3: Add dose row**

Create `Tensio/Features/Medications/DoseRowView.swift`:

```swift
import SwiftUI

struct DoseRowView: View {
    let medication: StoredMedication
    let onTaken: () -> Void
    let onSkipped: () -> Void

    var body: some View {
        ClinicSlipSurface {
            Text(medication.name)
                .font(.title3.weight(.semibold))
            Text(medication.dose)
                .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
            HStack {
                Button("Taken", action: onTaken)
                    .buttonStyle(.borderedProminent)
                    .tint(TensioTheme.ColorToken.evergreen)
                    .frame(minHeight: TensioTheme.Spacing.controlHeight)
                Button("Skipped", action: onSkipped)
                    .buttonStyle(.bordered)
                    .tint(TensioTheme.ColorToken.signalRed)
                    .frame(minHeight: TensioTheme.Spacing.controlHeight)
            }
        }
    }
}
```

- [ ] **Step 4: Add medication editor**

Create `Tensio/Features/Medications/MedicationEditorView.swift`:

```swift
import SwiftData
import SwiftUI

struct MedicationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var dose = ""
    @State private var hour = 8
    @State private var minute = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Medicine name", text: $name)
                TextField("Dose", text: $dose)
                DatePicker(
                    "Daily time",
                    selection: Binding(
                        get: { Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date() },
                        set: {
                            let components = Calendar.current.dateComponents([.hour, .minute], from: $0)
                            hour = components.hour ?? 8
                            minute = components.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
            .navigationTitle("Add medicine")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let draft = MedicationDraft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dose: dose.trimmingCharacters(in: .whitespacesAndNewlines),
            schedule: .daily(hour: hour, minute: minute),
            refillDate: nil
        )
        _ = try? MedicationRepository(modelContext: modelContext).saveMedication(draft)
        dismiss()
    }
}
```

- [ ] **Step 5: Add medication center**

Create `Tensio/Features/Medications/MedicationCenterView.swift`:

```swift
import SwiftData
import SwiftUI

struct MedicationCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var medications: [StoredMedication] = []
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if medications.isEmpty {
                    ClinicSlipSurface {
                        Text("No medicines yet")
                            .font(.title2.weight(.semibold))
                        Text("Add medicines to track taken, late, and skipped doses.")
                            .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
                    }
                } else {
                    ForEach(medications) { medication in
                        DoseRowView(
                            medication: medication,
                            onTaken: { log(medication, status: .taken) },
                            onSkipped: { log(medication, status: .skipped) }
                        )
                    }
                }

                PrimaryActionButton(title: "Add medicine", systemImage: "plus") {
                    showingEditor = true
                }
            }
            .padding(TensioTheme.Spacing.screen)
        }
        .background(TensioTheme.ColorToken.porcelain)
        .navigationTitle("Medicines")
        .task { load() }
        .sheet(isPresented: $showingEditor, onDismiss: load) {
            MedicationEditorView()
        }
    }

    private func load() {
        medications = (try? MedicationRepository(modelContext: modelContext).fetchMedications()) ?? []
    }

    private func log(_ medication: StoredMedication, status: DoseStatus) {
        try? MedicationRepository(modelContext: modelContext).logDose(
            medicationID: medication.id,
            takenAt: Date(),
            status: status
        )
        load()
    }
}
```

- [ ] **Step 6: Wire the Medicines tab**

Modify `Tensio/App/AppRootView.swift` so `.medicines` uses `MedicationCenterView()`:

```swift
case .medicines:
    MedicationCenterView()
```

- [ ] **Step 7: Run medication UI test**

Run:

```bash
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioUITests/MedicationCenterUITests
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Tensio/Features/Medications Tensio/App/AppRootView.swift TensioUITests/MedicationCenterUITests.swift
git commit -m "feat: add medication center"
```

---

### Task 10: Doctor Reports, PDF, and CSV Export

**Files:**
- Create: `Sources/TensioCore/ReportSummary.swift`
- Create: `Sources/TensioCore/CSVExport.swift`
- Create: `Tests/TensioCoreTests/ReportSummaryTests.swift`
- Create: `Tests/TensioCoreTests/CSVExportTests.swift`
- Create: `Tensio/Features/Reports/DoctorSummaryPDFRenderer.swift`
- Create: `Tensio/Features/Reports/FullLogPDFRenderer.swift`
- Create: `Tensio/Features/Reports/ShareExportService.swift`
- Create: `Tensio/Features/Reports/ReportsView.swift`
- Modify: `Tensio/App/AppRootView.swift`

**Interfaces:**
- Consumes: readings and medicines from repositories.
- Produces: `ReportSummary.make(readings:medications:now:)`.
- Produces: `CSVExport.make(readings:) -> String`.
- Produces: Reports tab with shareable PDF and CSV files.

- [ ] **Step 1: Write failing summary and CSV tests**

Create `Tests/TensioCoreTests/ReportSummaryTests.swift`:

```swift
import XCTest
@testable import TensioCore

final class ReportSummaryTests: XCTestCase {
    func testSummaryUsesRecentAverageAndHighestCategory() {
        let readings = [
            BloodPressureReading(measuredAt: Date(timeIntervalSince1970: 100), systolic: 128, diastolic: 78, pulse: 70),
            BloodPressureReading(measuredAt: Date(timeIntervalSince1970: 200), systolic: 142, diastolic: 92, pulse: 72)
        ]

        let summary = ReportSummary.make(readings: readings, medicineNames: ["Lisinopril"], now: Date(timeIntervalSince1970: 300))

        XCTAssertEqual(summary.averageSystolic, 135)
        XCTAssertEqual(summary.averageDiastolic, 85)
        XCTAssertEqual(summary.highestCategory, .stage2)
        XCTAssertEqual(summary.medicineNames, ["Lisinopril"])
    }
}
```

Create `Tests/TensioCoreTests/CSVExportTests.swift`:

```swift
import XCTest
@testable import TensioCore

final class CSVExportTests: XCTestCase {
    func testCSVIncludesHeaderAndReadings() {
        let readings = [
            BloodPressureReading(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                measuredAt: Date(timeIntervalSince1970: 0),
                systolic: 128,
                diastolic: 78,
                pulse: 70
            )
        ]

        let csv = CSVExport.make(readings: readings)

        XCTAssertTrue(csv.starts(with: "id,measured_at,systolic,diastolic,pulse,category"))
        XCTAssertTrue(csv.contains("128,78,70,elevated"))
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter ReportSummaryTests
swift test --filter CSVExportTests
```

Expected: FAIL because report types do not exist.

- [ ] **Step 3: Implement report summary and CSV**

Create `Sources/TensioCore/ReportSummary.swift`:

```swift
import Foundation

public struct ReportSummary: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let readingCount: Int
    public let averageSystolic: Int?
    public let averageDiastolic: Int?
    public let highestCategory: BloodPressureCategory?
    public let medicineNames: [String]

    public static func make(readings: [BloodPressureReading], medicineNames: [String], now: Date) -> ReportSummary {
        let averageSystolic = readings.isEmpty ? nil : readings.map(\.systolic).reduce(0, +) / readings.count
        let averageDiastolic = readings.isEmpty ? nil : readings.map(\.diastolic).reduce(0, +) / readings.count
        let categories = readings.map { BloodPressureCategory.classify(systolic: $0.systolic, diastolic: $0.diastolic) }
        let highest = categories.max { lhs, rhs in
            lhs.severityRank < rhs.severityRank
        }

        return ReportSummary(
            generatedAt: now,
            readingCount: readings.count,
            averageSystolic: averageSystolic,
            averageDiastolic: averageDiastolic,
            highestCategory: highest,
            medicineNames: medicineNames
        )
    }
}

private extension BloodPressureCategory {
    var severityRank: Int {
        switch self {
        case .normal: 0
        case .elevated: 1
        case .stage1: 2
        case .stage2: 3
        case .severe: 4
        }
    }
}
```

Create `Sources/TensioCore/CSVExport.swift`:

```swift
import Foundation

public enum CSVExport {
    public static func make(readings: [BloodPressureReading]) -> String {
        let header = "id,measured_at,systolic,diastolic,pulse,category"
        let rows = readings.map { reading in
            let category = BloodPressureCategory.classify(systolic: reading.systolic, diastolic: reading.diastolic)
            return [
                reading.id.uuidString,
                ISO8601DateFormatter().string(from: reading.measuredAt),
                String(reading.systolic),
                String(reading.diastolic),
                reading.pulse.map(String.init) ?? "",
                category.rawValue
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
```

- [ ] **Step 4: Add PDF renderers and share service**

Create `Tensio/Features/Reports/DoctorSummaryPDFRenderer.swift`:

```swift
import Foundation
import UIKit
import TensioCore

enum DoctorSummaryPDFRenderer {
    static func render(summary: ReportSummary, to url: URL) throws {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let title = "Tensio Doctor Summary"
            title.draw(at: CGPoint(x: 48, y: 48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)])

            let averageText: String
            if let sys = summary.averageSystolic, let dia = summary.averageDiastolic {
                averageText = "Average: \(sys)/\(dia) mm Hg"
            } else {
                averageText = "Average: No readings"
            }

            let body = """
            Readings: \(summary.readingCount)
            \(averageText)
            Highest category: \(summary.highestCategory?.displayName ?? "No readings")
            Medicines: \(summary.medicineNames.joined(separator: ", "))

            Tensio logs readings from an external blood pressure monitor. It does not diagnose conditions or recommend medication changes.
            """
            body.draw(in: CGRect(x: 48, y: 96, width: 516, height: 500), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        }
    }
}
```

Create `Tensio/Features/Reports/FullLogPDFRenderer.swift`:

```swift
import Foundation
import UIKit

enum FullLogPDFRenderer {
    static func render(readings: [StoredReading], to url: URL) throws {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            "Tensio Reading Log".draw(at: CGPoint(x: 48, y: 48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)])

            var y: CGFloat = 96
            for reading in readings.prefix(30) {
                let row = "\(reading.measuredAt.formatted(date: .abbreviated, time: .shortened)) - \(reading.systolic)/\(reading.diastolic)"
                row.draw(at: CGPoint(x: 48, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                y += 22
            }
        }
    }
}
```

Create `Tensio/Features/Reports/ShareExportService.swift`:

```swift
import Foundation
import TensioCore

enum ShareExportService {
    static func temporaryURL(filename: String) -> URL {
        FileManager.default.temporaryDirectory.appending(path: filename)
    }

    static func writeCSV(_ csv: String, filename: String = "tensio-readings.csv") throws -> URL {
        let url = temporaryURL(filename: filename)
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}
```

- [ ] **Step 5: Add Reports view**

Create `Tensio/Features/Reports/ReportsView.swift`:

```swift
import SwiftData
import SwiftUI
import TensioCore

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportedURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ClinicSlipSurface {
                Text("Doctor report")
                    .font(.title2.weight(.semibold))
                Text("Create a concise summary or full log to share before a visit.")
                    .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
            }

            PrimaryActionButton(title: "Create summary PDF", systemImage: "doc.text") {
                exportedURL = try? createSummaryPDF()
            }

            SecondaryActionButton(title: "Create CSV", systemImage: "tablecells") {
                exportedURL = try? createCSV()
            }

            if let exportedURL {
                ShareLink(item: exportedURL) {
                    Label("Share report", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
                }
            }
        }
        .padding(TensioTheme.Spacing.screen)
        .background(TensioTheme.ColorToken.porcelain)
        .navigationTitle("Report")
    }

    private func createSummaryPDF() throws -> URL {
        let readings = try ReadingRepository(modelContext: modelContext).fetchReadings(limit: 90)
        let medications = try MedicationRepository(modelContext: modelContext).fetchMedications()
        let coreReadings = readings.map {
            BloodPressureReading(id: $0.id, measuredAt: $0.measuredAt, systolic: $0.systolic, diastolic: $0.diastolic, pulse: $0.pulse)
        }
        let summary = ReportSummary.make(readings: coreReadings, medicineNames: medications.map(\.name), now: Date())
        let url = ShareExportService.temporaryURL(filename: "tensio-doctor-summary.pdf")
        try DoctorSummaryPDFRenderer.render(summary: summary, to: url)
        return url
    }

    private func createCSV() throws -> URL {
        let readings = try ReadingRepository(modelContext: modelContext).fetchReadings(limit: 1_000)
        let coreReadings = readings.map {
            BloodPressureReading(id: $0.id, measuredAt: $0.measuredAt, systolic: $0.systolic, diastolic: $0.diastolic, pulse: $0.pulse)
        }
        return try ShareExportService.writeCSV(CSVExport.make(readings: coreReadings))
    }
}
```

- [ ] **Step 6: Wire Report tab**

Modify `Tensio/App/AppRootView.swift` so `.report` uses `ReportsView()`:

```swift
case .report:
    ReportsView()
```

- [ ] **Step 7: Run report tests and full app tests**

Run:

```bash
swift test --filter ReportSummaryTests
swift test --filter CSVExportTests
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Sources/TensioCore Tests/TensioCoreTests Tensio/Features/Reports Tensio/App/AppRootView.swift
git commit -m "feat: add doctor report exports"
```

---

### Task 11: Privacy Settings, Backup, and HealthKit

**Files:**
- Create: `Sources/TensioCore/BackupEnvelope.swift`
- Create: `Tests/TensioCoreTests/BackupEnvelopeTests.swift`
- Create: `Tensio/Features/Settings/HealthKitSyncService.swift`
- Create: `Tensio/Features/Settings/BackupImportExportService.swift`
- Create: `Tensio/Features/Settings/PrivacySettingsView.swift`
- Create: `TensioTests/HealthKitSyncServiceTests.swift`
- Create: `TensioTests/BackupImportExportServiceTests.swift`
- Create: `Tensio/Tensio.entitlements`
- Modify: `Tensio/App/AppRootView.swift`
- Modify: `Tensio.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `BackupEnvelope`.
- Produces: `BackupImportExportService.exportBackup(envelope:passphrase:)`.
- Produces: `HealthKitSyncService` with a fakeable adapter.
- Consumed by: Settings tab.

- [ ] **Step 1: Write failing backup envelope test**

Create `Tests/TensioCoreTests/BackupEnvelopeTests.swift`:

```swift
import XCTest
@testable import TensioCore

final class BackupEnvelopeTests: XCTestCase {
    func testBackupEnvelopeRoundTrips() throws {
        let envelope = BackupEnvelope(
            schemaVersion: 1,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            readings: [
                BloodPressureReading(
                    id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                    measuredAt: Date(timeIntervalSince1970: 1),
                    systolic: 120,
                    diastolic: 78,
                    pulse: 70
                )
            ],
            medicineNames: ["Lisinopril"]
        )

        let data = try JSONEncoder.tensio.encode(envelope)
        let decoded = try JSONDecoder.tensio.decode(BackupEnvelope.self, from: data)

        XCTAssertEqual(decoded, envelope)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
swift test --filter BackupEnvelopeTests
```

Expected: FAIL because `BackupEnvelope` does not exist.

- [ ] **Step 3: Implement backup envelope**

Create `Sources/TensioCore/BackupEnvelope.swift`:

```swift
import Foundation

public struct BackupEnvelope: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let createdAt: Date
    public let readings: [BloodPressureReading]
    public let medicineNames: [String]

    public init(schemaVersion: Int, createdAt: Date, readings: [BloodPressureReading], medicineNames: [String]) {
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.readings = readings
        self.medicineNames = medicineNames
    }
}

public extension JSONEncoder {
    static var tensio: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

public extension JSONDecoder {
    static var tensio: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
```

- [ ] **Step 4: Add HealthKit service with fakeable adapter**

Create `Tensio/Features/Settings/HealthKitSyncService.swift`:

```swift
import Foundation
import HealthKit
import TensioCore

protocol HealthKitAdapting {
    func requestAuthorization() async throws -> Bool
    func save(reading: BloodPressureReading) async throws
}

final class HealthKitSyncService {
    private let adapter: HealthKitAdapting

    init(adapter: HealthKitAdapting = LiveHealthKitAdapter()) {
        self.adapter = adapter
    }

    func connect() async throws -> Bool {
        try await adapter.requestAuthorization()
    }

    func export(readings: [BloodPressureReading]) async throws {
        for reading in readings {
            try await adapter.save(reading: reading)
        }
    }
}

final class LiveHealthKitAdapter: HealthKitAdapting {
    private let store = HKHealthStore()

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        try await store.requestAuthorization(toShare: [systolic, diastolic], read: [systolic, diastolic])
        return true
    }

    func save(reading: BloodPressureReading) async throws {
        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let sys = HKQuantitySample(
            type: systolicType,
            quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(reading.systolic)),
            start: reading.measuredAt,
            end: reading.measuredAt
        )
        let dia = HKQuantitySample(
            type: diastolicType,
            quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(reading.diastolic)),
            start: reading.measuredAt,
            end: reading.measuredAt
        )
        try await store.save([sys, dia])
    }
}

#if DEBUG
final class FakeHealthKitAdapter: HealthKitAdapting {
    var didAuthorize = true
    private(set) var savedReadings: [BloodPressureReading] = []

    func requestAuthorization() async throws -> Bool {
        didAuthorize
    }

    func save(reading: BloodPressureReading) async throws {
        savedReadings.append(reading)
    }
}
#endif
```

- [ ] **Step 5: Add backup service**

Create `Tensio/Features/Settings/BackupImportExportService.swift`:

```swift
import Foundation
import CryptoKit
import TensioCore

enum BackupImportExportService {
    static func exportBackup(envelope: BackupEnvelope, passphrase: String) throws -> Data {
        let payload = try JSONEncoder.tensio.encode(envelope)
        let key = SymmetricKey(data: SHA256.hash(data: Data(passphrase.utf8)))
        let sealed = try ChaChaPoly.seal(payload, using: key)
        return sealed.combined
    }

    static func importBackup(data: Data, passphrase: String) throws -> BackupEnvelope {
        let key = SymmetricKey(data: SHA256.hash(data: Data(passphrase.utf8)))
        let box = try ChaChaPoly.SealedBox(combined: data)
        let payload = try ChaChaPoly.open(box, using: key)
        return try JSONDecoder.tensio.decode(BackupEnvelope.self, from: payload)
    }
}
```

- [ ] **Step 6: Add service tests**

Create `TensioTests/HealthKitSyncServiceTests.swift`:

```swift
import XCTest
import TensioCore
@testable import Tensio

final class HealthKitSyncServiceTests: XCTestCase {
    func testExportsReadingsThroughAdapter() async throws {
        let adapter = FakeHealthKitAdapter()
        let service = HealthKitSyncService(adapter: adapter)
        let reading = BloodPressureReading(measuredAt: Date(timeIntervalSince1970: 1), systolic: 120, diastolic: 78, pulse: nil)

        let connected = try await service.connect()
        try await service.export(readings: [reading])

        XCTAssertTrue(connected)
        XCTAssertEqual(adapter.savedReadings, [reading])
    }
}
```

Create `TensioTests/BackupImportExportServiceTests.swift`:

```swift
import XCTest
import TensioCore
@testable import Tensio

final class BackupImportExportServiceTests: XCTestCase {
    func testEncryptedBackupRoundTripsWithPassphrase() throws {
        let envelope = BackupEnvelope(
            schemaVersion: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            readings: [],
            medicineNames: ["Amlodipine"]
        )

        let encrypted = try BackupImportExportService.exportBackup(envelope: envelope, passphrase: "correct horse battery staple")
        let decoded = try BackupImportExportService.importBackup(data: encrypted, passphrase: "correct horse battery staple")

        XCTAssertEqual(decoded, envelope)
    }
}
```

- [ ] **Step 7: Add Privacy Settings view**

Create `Tensio/Features/Settings/PrivacySettingsView.swift`:

```swift
import SwiftData
import SwiftUI
import TensioCore

struct PrivacySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var status = "Your data stays on this iPhone unless you export or connect Apple Health."
    @State private var passphrase = ""
    @State private var exportedBackupURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ClinicSlipSurface {
                    Text("Privacy")
                        .font(.title2.weight(.semibold))
                    Text(status)
                        .foregroundStyle(TensioTheme.ColorToken.warmGraphite)
                }

                PrimaryActionButton(title: "Connect Apple Health", systemImage: "heart") {
                    Task {
                        do {
                            let connected = try await HealthKitSyncService().connect()
                            status = connected ? "Apple Health is connected." : "Apple Health is not available on this device."
                        } catch {
                            status = "Apple Health permission was not granted."
                        }
                    }
                }

                SecureField("Backup passphrase", text: $passphrase)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .accessibilityHint("Used only to encrypt the exported backup file")

                SecondaryActionButton(title: "Export backup", systemImage: "lock.doc") {
                    do {
                        exportedBackupURL = try createEncryptedBackup()
                        status = "Backup file is ready to share."
                    } catch {
                        status = "Backup was not created. Enter a passphrase and try again."
                    }
                }
                .disabled(passphrase.count < 8)

                if let exportedBackupURL {
                    ShareLink(item: exportedBackupURL) {
                        Label("Share backup", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: TensioTheme.Spacing.controlHeight)
                    }
                }
            }
            .padding(TensioTheme.Spacing.screen)
        }
        .background(TensioTheme.ColorToken.porcelain)
        .navigationTitle("Settings")
    }

    private func createEncryptedBackup() throws -> URL {
        let readings = try ReadingRepository(modelContext: modelContext).fetchReadings(limit: 10_000)
        let medications = try MedicationRepository(modelContext: modelContext).fetchMedications()
        let coreReadings = readings.map {
            BloodPressureReading(id: $0.id, measuredAt: $0.measuredAt, systolic: $0.systolic, diastolic: $0.diastolic, pulse: $0.pulse)
        }
        let envelope = BackupEnvelope(
            schemaVersion: 1,
            createdAt: Date(),
            readings: coreReadings,
            medicineNames: medications.map(\.name)
        )
        let data = try BackupImportExportService.exportBackup(envelope: envelope, passphrase: passphrase)
        let url = FileManager.default.temporaryDirectory.appending(path: "tensio-backup.tensiobackup")
        try data.write(to: url, options: .atomic)
        return url
    }
}
```

- [ ] **Step 8: Add HealthKit capability**

Modify `Tensio.xcodeproj/project.pbxproj` to enable the HealthKit capability for the `Tensio` app target:

```text
SystemCapabilities:
  com.apple.HealthKit:
    enabled: 1
Entitlements file:
  Tensio/Tensio.entitlements
```

Create `Tensio/Tensio.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 9: Wire Settings tab**

Modify `Tensio/App/AppRootView.swift` so `.settings` uses `PrivacySettingsView()`:

```swift
case .settings:
    PrivacySettingsView()
```

- [ ] **Step 10: Run tests**

Run:

```bash
swift test --filter BackupEnvelopeTests
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioTests/HealthKitSyncServiceTests
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TensioTests/BackupImportExportServiceTests
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS.

- [ ] **Step 11: Commit**

```bash
git add Sources/TensioCore Tests/TensioCoreTests Tensio/Features/Settings TensioTests Tensio/App/AppRootView.swift Tensio.xcodeproj Tensio/Tensio.entitlements
git commit -m "feat: add privacy settings and HealthKit"
```

---

### Task 12: Final Accessibility, Localization, and Release QA

**Files:**
- Modify: `Tensio/Resources/Localizable.xcstrings`
- Create: `docs/release/mvp-qa-checklist.md`
- Modify: all feature views with final accessibility fixes found by this task
- Modify: tests only when their expectations need to match accessible labels that changed in app code

**Interfaces:**
- Consumes: all MVP views and flows.
- Produces: localization coverage, QA checklist, final UI pass.

- [ ] **Step 1: Add release QA checklist**

Create `docs/release/mvp-qa-checklist.md`:

```markdown
# Tensio MVP QA Checklist

## Capture

- Manual reading entry uses controls at least 56 pt tall.
- Systolic and diastolic are required.
- Pulse is optional.
- Saved reading appears on Today and Log.
- Severe readings show repeat-measurement and emergency-symptom guidance.

## Coach

- Measurement technique list is readable at Accessibility 3 Dynamic Type.
- 1-minute timer counts down and text does not overlap.
- 7-day reminder setup handles denied notification permission.

## Medicines

- Empty state is clear.
- Medicine can be added.
- Dose can be marked taken or skipped.

## Reports

- Summary PDF is generated.
- CSV is generated.
- Share sheet opens for generated files.

## Privacy

- No account is required.
- App works in airplane mode.
- Apple Health connection is optional.
- Backup export is encrypted.

## Accessibility

- VoiceOver reads primary controls by action name.
- Color is not the only status signal.
- All primary controls are reachable without hidden gestures.
- Large text does not clip in Today, Entry, Medicines, Report, and Settings.
```

- [ ] **Step 2: Fill string catalog**

Populate `Tensio/Resources/Localizable.xcstrings` with every user-facing string from app views. Minimum strings:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "Add reading" : {},
    "Save reading" : {},
    "Today" : {},
    "Log" : {},
    "Medicines" : {},
    "Report" : {},
    "Settings" : {},
    "No readings yet" : {},
    "No medicines yet" : {},
    "Call emergency services" : {},
    "Take another reading" : {},
    "Create summary PDF" : {},
    "Create CSV" : {},
    "Connect Apple Health" : {},
    "Export backup" : {}
  },
  "version" : "1.0"
}
```

- [ ] **Step 3: Run full automated verification**

Run:

```bash
swift test
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS.

- [ ] **Step 4: Capture screenshots for design review**

Use XcodeBuildMCP if available:

```text
Call mcp__XcodeBuildMCP.session_show_defaults
Call mcp__XcodeBuildMCP.build_sim
Call mcp__XcodeBuildMCP.launch_app_sim
Call mcp__XcodeBuildMCP.screenshot with returnFormat path
```

Capture these states:

```text
Onboarding
Today empty
Entry form
Today with reading
Medicines empty
Reports
Settings
```

Reviewer acceptance:

```text
No text overlap.
No clipped primary buttons.
No card inside another card.
Clinic slip motif is visible on Today, Entry, Medicines, Report, and Settings.
Palette does not read as one-note blue, purple, beige, or dark slate.
```

- [ ] **Step 5: Fix accessibility or layout findings**

For each finding, change the smallest affected view. Required examples:

```swift
.minimumScaleFactor(0.85)
.lineLimit(2)
.dynamicTypeSize(...DynamicTypeSize.accessibility3)
.accessibilityLabel("Blood pressure \(reading.systolic) over \(reading.diastolic), \(style.label)")
```

Do not reduce the `56 pt` primary control minimum height.

- [ ] **Step 6: Run final verification**

Run:

```bash
swift test
xcodebuild test -project Tensio.xcodeproj -scheme Tensio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Tensio docs/release
git commit -m "chore: finalize MVP accessibility QA"
```

---

## Final Whole-Branch Review

After Task 12 passes:

- Run a final code review subagent using `superpowers:requesting-code-review`.
- Verify no network clients, analytics SDKs, LLM calls, camera capture, or Bluetooth sync entered the MVP.
- Verify all severe-reading behavior is deterministic and covered by tests.
- Verify the app builds and tests on an iOS simulator.
- Verify the final branch contains one commit per task.

## Post-MVP Backlog

These are intentionally outside the MVP and must not be pulled into the task sequence:

- Camera reading scan using Vision.
- Bluetooth monitor sync.
- AI trend summaries with retrieval-grounded guardrails.
- Caregiver sharing.
- iCloud sync.
- Multi-user profiles.
- Widgets.
- Subscription/paywall.
- Spanish and Romanian translations after clinical copy review.

## Self-Review

- Spec coverage: The plan covers effortless manual entry, deterministic clinical interpretation, measurement coaching, medication tracking, doctor-ready export, local privacy, backup, HealthKit, senior accessibility, and premium visual direction from the research report.
- Placeholder scan: No `TBD`, `TODO`, `implement later`, or "similar to Task N" instructions are present.
- Type consistency: Core types flow from `TensioCore` into persistence, entry, dashboard, reports, backup, and HealthKit with matching names.
- Scope check: Bluetooth, camera scanning, AI, caregiver sharing, and cloud sync are excluded from MVP to protect implementation focus.
