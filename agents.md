# Tensio Working Notes

## Product

Tensio is a local-first, no-account iOS blood pressure companion for seniors and caregivers preparing for clinician visits.

## Non-Negotiables

- App, scheme, project, target, and visible marketing name are all `Tensio`.
- Bundle identifier is `com.andreibalu.tensio`.
- MVP is iPhone-only with `TARGETED_DEVICE_FAMILY = 1`.
- No server, account system, analytics SDK, third-party SDK, LLM, camera scanning, or Bluetooth sync in MVP.
- Tensio logs readings from external blood pressure monitors; it never claims to measure blood pressure from the phone alone.
- Severe reading guidance is deterministic and follows AHA thresholds in `TensioCore`.
- Every permission, HealthKit, backup, networking, or data-storage change updates `privacy-policy.md`, `support.md`, `EULA.md`, and `Tensio/Resources/PrivacyInfo.xcprivacy` in the same change.

## Implementation

- Before choosing or implementing a daily slice, use
  `docs/superpowers/plans/2026-06-19-tensio-mvp.md` and the original Tensio
  research as source of truth for product scope, clinical behavior, UX, and
  privacy. Read `/Users/andreibalu/CODE/learnings` and
  `/Users/andreibalu/CODE/xcode/Ebooker/AGENTS.md` only for reusable
  architecture, SwiftUI/SwiftData, tooling, App Store, and workflow patterns.
  Do not import Ebooker/Unpaged product behavior, naming, AI, audio, catalog,
  IAP, or sync decisions unless the Tensio plan explicitly calls for them.
- Keep deterministic domain rules in `Sources/TensioCore`.
- Use SwiftUI plus lightweight MVVM in the app target.
- Views own `@Query`, `@AppStorage`, and UI state.
- View models are `@MainActor @Observable` when async workflow state is needed.
- Services are protocol typed with default concrete implementations.
- SwiftData models avoid `@Attribute(.unique)` so future CloudKit sync remains possible.
- UI must support Dynamic Type through Accessibility 3, and primary controls must be at least 56 pt tall.
- Prefer filesystem-synchronized Xcode groups: app files under `Tensio/`, unit tests under `TensioTests/`, UI tests under `TensioUITests/`.
