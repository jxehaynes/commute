# Commute — Agent Build Specification
**Version:** 0.1
**Companion to:** `commute-product-spec.md` (v0.2)
**Scope:** v0 scaffold — mock data, full onboarding, home screen, route results screen
**iOS target:** 17.0+, Swift 5.9+, SwiftUI throughout

---

## How to Use This Document

This spec tells the agent exactly what to build, in what order, and what not to touch.
Read it top to bottom before writing a single line of code.

- **DO** follow file paths exactly. The project uses synced folder roots. Files placed outside them will not appear in Xcode.
- **DO** ask (via a code comment marked `// AGENT QUESTION:`) if a decision is ambiguous. Do not invent.
- **DO NOT** add third-party dependencies without a note in the PR description explaining why.
- **DO NOT** modify anything in `preview/` — that folder is reserved.
- **DO NOT** build anything listed in Section 10 (explicitly out of scope for this slice).

The product spec (`commute-product-spec.md`) is the source of truth for *what* the product does. This document is the source of truth for *how to build it right now*.

If this document conflicts with .cursor/rules/swiftui-ios.mdc, the agent should ensure that the codebase is edited so it knows what it has built.

---

## 1. Repo Structure Contract

The following synced roots are wired into `project.pbxproj`. All new files must live inside one of them.

```
commute/
├── app/                  # App lifecycle, routing, entry point
├── core/                 # Shared models, services, utilities, design system
├── features/             # One subfolder per feature
│   └── home/
│       ├── views/
│       ├── view-models/
│       └── models/
└── preview/              # Preview helpers only — do not touch
```

New feature folders follow the same pattern:
```
features/{feature-name}/
├── views/
├── view-models/
└── models/
```

No file should be placed at the root of `commute/` directly.

---

## 2. Step 0 — Update Theme.swift Before Anything Else

`core/Theme.swift` exists but its tokens conflict with the product spec. Update it before building any screen. This is the first task.

### 2.1 Token Renames

The agent must rename the following tokens **in place** (update all call sites simultaneously — a rename, not a deletion):

| Current name | New name | Reason |
|---|---|---|
| `Colors.background` | `Colors.backgroundPrimary` | Matches spec token `background.primary` |
| `Colors.backgroundSecondary` | `Colors.backgroundSurface` | Matches spec token `background.surface` |
| `Colors.surface` | `Colors.backgroundElevated` | Matches spec token |
| `Colors.surfaceElevated` | *(delete — merge into backgroundElevated)* | Duplicate |
| `Colors.success` | `Colors.statusGood` | Matches spec token `status.good` |
| `Colors.warning` | `Colors.statusWarning` | Matches spec token `status.warning` |
| `Colors.error` | `Colors.statusDisrupted` | Matches spec token `status.disrupted` |
| `Colors.info` | *(delete — unused in spec)* | Not needed in v1 |
| `Colors.routeLine` | *(keep — maps to accent)* | Already correct |
| `Colors.onTime` | *(keep — alias of statusGood)* | Already correct |
| `Colors.delayed` | *(keep — alias of statusWarning)* | Already correct |

### 2.2 Colour Value Updates

Update the following raw values to match spec exactly:

```swift
// background.primary
static let backgroundPrimary = Color.adaptive(
    light: UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1), // #F5F5F7
    dark:  UIColor(red: 0.051, green: 0.051, blue: 0.059, alpha: 1)  // #0D0D0F
)

// background.surface
static let backgroundSurface = Color.adaptive(
    light: .white,
    dark:  UIColor(red: 0.102, green: 0.102, blue: 0.118, alpha: 1)  // #1A1A1E
)

// background.elevated
static let backgroundElevated = Color.adaptive(
    light: UIColor(red: 0.922, green: 0.922, blue: 0.941, alpha: 1), // #EBEBF0
    dark:  UIColor(red: 0.141, green: 0.141, blue: 0.157, alpha: 1)  // #242428
)

// text.primary
static let textPrimary = Color.adaptive(
    light: UIColor(red: 0.102, green: 0.102, blue: 0.118, alpha: 1), // #1A1A1E
    dark:  UIColor(red: 0.941, green: 0.941, blue: 0.949, alpha: 1)  // #F0F0F2
)

// text.secondary
static let textSecondary = Color.adaptive(
    light: UIColor(red: 0.431, green: 0.431, blue: 0.502, alpha: 1), // #6E6E80
    dark:  UIColor(red: 0.541, green: 0.541, blue: 0.604, alpha: 1)  // #8A8A9A
)

// status.good — match iOS system green exactly
static let statusGood = Color.adaptive(
    light: UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1), // #34C759
    dark:  UIColor(red: 0.188, green: 0.820, blue: 0.345, alpha: 1)  // #30D158
)

// status.warning
static let statusWarning = Color.adaptive(
    light: UIColor(red: 1.000, green: 0.584, blue: 0.000, alpha: 1), // #FF9500
    dark:  UIColor(red: 1.000, green: 0.624, blue: 0.039, alpha: 1)  // #FF9F0A
)

// status.disrupted
static let statusDisrupted = Color.adaptive(
    light: UIColor(red: 1.000, green: 0.231, blue: 0.188, alpha: 1), // #FF3B30
    dark:  UIColor(red: 1.000, green: 0.271, blue: 0.227, alpha: 1)  // #FF453A
)
```

### 2.3 Font Stack Update

The existing `Fonts` enum uses `.rounded` design for display sizes. This contradicts the typographic direction (departure board — utilitarian, not friendly). Replace as follows:

```swift
enum Fonts {
    // Display — used for route results header (34pt, mixed with serif)
    static let display = Font.system(size: 34, weight: .regular, design: .default)

    // Route summary line ("Via the Elizabeth Line")
    static let routeSummary = Font.system(size: 17, weight: .regular, design: .default)

    // Route time ("22 mins") — right-aligned, semibold
    static let routeTime = Font.system(size: 17, weight: .semibold, design: .default)

    // Journey detail — expanded row content
    static let journeyDetail = Font.system(size: 15, weight: .regular, design: .default)

    // Secondary — status lines, timestamps
    static let secondary = Font.system(size: 13, weight: .regular, design: .default)

    // Line chip label
    static let lineChip = Font.system(size: 13, weight: .semibold, design: .default)

    // Tabular figures — for all times and countdowns
    // Usage: Text("08:47").font(Fonts.routeTime).monospacedDigit()
    // Do NOT create a separate token for this — apply .monospacedDigit() modifier at call site

    // Body / general UI
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let bodyEmphasis = Font.system(.body, design: .default, weight: .medium)
    static let caption = Font.system(.caption, design: .default, weight: .regular)
}
```

Remove `largeTitle`, `title`, `title2`, `title3`, `headline`, `callout`, `subheadline`, `footnote`, `caption2`, `monoBody`, `monoCaption` — they are replaced by the above.

### 2.4 Add Accent Colour Infrastructure

Add the following to `Theme.swift` **below** the `Colors` enum. This is the runtime accent system — the user's chosen colour replaces the static `accent` token:

```swift
// MARK: - Accent Colour

enum AccentStyle: Codable, Equatable {
    case solid(SolidAccent)
    case gradient(GradientAccent)
}

enum SolidAccent: String, Codable, CaseIterable {
    case blue, purple, pink, red, orange, yellow, green, graphite

    var color: Color {
        switch self {
        case .blue:     return Color(uiColor: UIColor.systemBlue)
        case .purple:   return Color(uiColor: UIColor.systemPurple)
        case .pink:     return Color(uiColor: UIColor.systemPink)
        case .red:      return Color(uiColor: UIColor.systemRed)
        case .orange:   return Color(uiColor: UIColor.systemOrange)
        case .yellow:   return Color(uiColor: UIColor.systemYellow)
        case .green:    return Color(uiColor: UIColor.systemGreen)
        case .graphite: return Color(uiColor: UIColor.systemGray)
        }
    }
}

enum GradientAccent: String, Codable, CaseIterable {
    case aurora, dusk, deepSpace, monochrome, solar

    // Returns stops for LinearGradient
    var stops: [Gradient.Stop] {
        switch self {
        case .aurora:
            return [.init(color: Color(hex: "00C9B1"), location: 0),
                    .init(color: Color(hex: "7B5EA7"), location: 1)]
        case .dusk:
            return [.init(color: Color(hex: "F5A623"), location: 0),
                    .init(color: Color(hex: "E8506A"), location: 1)]
        case .deepSpace:
            return [.init(color: Color(hex: "0A1F5C"), location: 0),
                    .init(color: Color(hex: "0066FF"), location: 1)]
        case .monochrome:
            return [.init(color: Color(hex: "3A3A3C"), location: 0),
                    .init(color: Color(hex: "AEAEB2"), location: 1)]
        case .solar:
            return [.init(color: Color(hex: "F7C948"), location: 0),
                    .init(color: Color(hex: "FF6B4A"), location: 1)]
        }
    }
}
```

Add a `Color(hex:)` initialiser to `core/Extensions/Color+Hex.swift` (create file):

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

### 2.5 Add Serif Font Support

Create `core/Extensions/Font+Serif.swift`:

```swift
import SwiftUI

extension Font {
    /// Playfair Display italic — used exclusively for personal nouns
    /// (user's name, destination names). Never used for body copy or times.
    static func playfairItalic(size: CGFloat) -> Font {
        Font.custom("PlayfairDisplay-Italic", size: size)
    }
}
```

Add `PlayfairDisplay-Italic.ttf` to the app bundle under `core/Resources/Fonts/`.
Register it in `Info.plist` under `UIAppFonts`:
```xml
<key>UIAppFonts</key>
<array>
    <string>PlayfairDisplay-Italic.ttf</string>
</array>
```

Download source: Google Fonts — Playfair Display. SIL Open Font Licence 1.1. Include `OFL.txt` in `core/Resources/Fonts/`.

---

## 3. App Lifecycle & Routing

### 3.1 Entry Point

`app/CommuteApp.swift` — replace template content:

```swift
@main
struct CommuteApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(appState)
        }
    }
}
```

### 3.2 AppState

Create `app/AppState.swift`:

```swift
@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var accentStyle: AccentStyle
    @Published var useSerif: Bool

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding.complete")
        // Accent and font defaults — blue + sans until user sets them
        if let data = UserDefaults.standard.data(forKey: "accent.style"),
           let decoded = try? JSONDecoder().decode(AccentStyle.self, from: data) {
            self.accentStyle = decoded
        } else {
            self.accentStyle = .solid(.blue)
        }
        self.useSerif = UserDefaults.standard.bool(forKey: "font.serif")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboarding.complete")
    }

    func setAccent(_ style: AccentStyle) {
        accentStyle = style
        if let data = try? JSONEncoder().encode(style) {
            UserDefaults.standard.set(data, forKey: "accent.style")
        }
    }

    func setFont(serif: Bool) {
        useSerif = serif
        UserDefaults.standard.set(serif, forKey: "font.serif")
    }
}
```

### 3.3 AppRouter

Create `app/AppRouter.swift`:

```swift
struct AppRouter: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingFlowView()
        }
    }
}
```

No `NavigationStack` at this level — each major flow owns its own navigation context.

---

## 4. Mock Data Layer

All data in v0 is mock. The mock layer must be structured so that real service implementations can be dropped in later without touching view or view-model code.

### 4.1 Protocols (create in `core/Services/`)

`core/Services/RouteProviding.swift`:
```swift
protocol RouteProviding {
    func fetchRoutes(from: SavedLocation, to: SavedLocation) async throws -> [Route]
}
```

`core/Services/DisruptionProviding.swift`:
```swift
protocol DisruptionProviding {
    func fetchDisruptions(for lines: [TfLLine]) async throws -> [Disruption]
}
```

### 4.2 Mock Implementations (create in `core/Mocks/`)

`core/Mocks/MockRouteProvider.swift`:
```swift
struct MockRouteProvider: RouteProviding {
    func fetchRoutes(from: SavedLocation, to: SavedLocation) async throws -> [Route] {
        // Simulate network latency
        try await Task.sleep(for: .seconds(0.8))
        return Route.mockRoutes(from: from, to: to)
    }
}
```

`core/Mocks/MockDisruptionProvider.swift`:
```swift
struct MockDisruptionProvider: DisruptionProviding {
    var simulateDisruption: Bool = false

    func fetchDisruptions(for lines: [TfLLine]) async throws -> [Disruption] {
        guard simulateDisruption else { return [] }
        return [Disruption(line: .central, severity: .minorDelays, summary: "Minor delays on the Central line.")]
    }
}
```

### 4.3 Mock Model Extensions (create in `core/Mocks/`)

`core/Mocks/Route+Mock.swift`:
```swift
extension Route {
    static func mockRoutes(from: SavedLocation, to: SavedLocation) -> [Route] {
        [
            Route(
                summary: "Via the Elizabeth line",
                totalMinutes: 22,
                legs: [
                    .walk(minutes: 7, distanceMiles: 0.4),
                    .transit(line: .elizabeth, from: "Tottenham Court Road", to: "Paddington", departureTime: "08:47", platform: "P6", stops: 3),
                    .walk(minutes: 4, distanceMiles: 0.2)
                ],
                status: .goodService
            ),
            Route(
                summary: "Via the Central line",
                totalMinutes: 28,
                legs: [
                    .walk(minutes: 5, distanceMiles: 0.3),
                    .transit(line: .central, from: "Holborn", to: "Notting Hill Gate", departureTime: "08:51", platform: nil, stops: 5),
                    .walk(minutes: 6, distanceMiles: 0.35)
                ],
                status: .minorDelays
            ),
            Route(
                summary: "Via the Circle line",
                totalMinutes: 34,
                legs: [
                    .walk(minutes: 9, distanceMiles: 0.5),
                    .transit(line: .circle, from: "Farringdon", to: "Bayswater", departureTime: "08:55", platform: nil, stops: 7),
                    .walk(minutes: 3, distanceMiles: 0.15)
                ],
                status: .goodService
            )
        ]
    }
}
```

---

## 5. Core Models

Create all model files in `core/Models/`.

### `core/Models/SavedLocation.swift`
```swift
import Foundation
import CoreLocation

struct SavedLocation: Codable, Identifiable, Equatable {
    let id: UUID
    var label: LocationLabel
    var customName: String?  // only for .other
    var address: String
    var coordinate: CLLocationCoordinate2D

    var displayName: String {
        switch label {
        case .home:   return "Home"
        case .work:   return customName ?? "Work"
        case .other:  return customName ?? "Somewhere else"
        }
    }

    enum LocationLabel: Codable, Equatable {
        case home, work, other
    }
}

extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lat = try container.decode(Double.self)
        let lng = try container.decode(Double.self)
        self.init(latitude: lat, longitude: lng)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
}
```

### `core/Models/Route.swift`
```swift
import Foundation

struct Route: Identifiable, Equatable {
    let id: UUID = UUID()
    let summary: String         // "Via the Elizabeth line"
    let totalMinutes: Int
    let legs: [RouteLeg]
    let status: LineStatus

    enum LineStatus: Equatable {
        case goodService
        case minorDelays
        case severeDelays
        case suspended
        case unknown
    }
}

enum RouteLeg: Equatable {
    case walk(minutes: Int, distanceMiles: Double)
    case transit(
        line: TfLLine,
        from: String,
        to: String,
        departureTime: String,   // "08:47" — display string only
        platform: String?,
        stops: Int
    )
}
```

### `core/Models/TfLLine.swift`
```swift
import SwiftUI

enum TfLLine: String, Codable, CaseIterable {
    case bakerloo, central, circle, district, elizabethLine, hammersmithAndCity
    case jubilee, metropolitan, northern, piccadilly, victoria, waterlooAndCity
    case overground, dlr, elizabethExpress, tflRail, liberty, lioness, mildmay
    case suffragette, weaver, windrush
    case nationalRail

    var displayName: String {
        switch self {
        case .elizabethLine:        return "Elizabeth"
        case .hammersmithAndCity:   return "H&C"
        case .waterlooAndCity:      return "W&C"
        case .overground:           return "Overground"
        case .dlr:                  return "DLR"
        case .nationalRail:         return "National Rail"
        default:                    return rawValue.capitalized
        }
    }

    /// Official TfL brand colours
    var brandColor: Color {
        switch self {
        case .bakerloo:            return Color(hex: "B36305")
        case .central:             return Color(hex: "E32017")
        case .circle:              return Color(hex: "FFD300")
        case .district:            return Color(hex: "00782A")
        case .elizabethLine:       return Color(hex: "6950A1")
        case .hammersmithAndCity:  return Color(hex: "F3A9BB")
        case .jubilee:             return Color(hex: "A0A5A9")
        case .metropolitan:        return Color(hex: "9B0056")
        case .northern:            return Color(hex: "000000")
        case .piccadilly:          return Color(hex: "003688")
        case .victoria:            return Color(hex: "0098D4")
        case .waterlooAndCity:     return Color(hex: "95CDBA")
        case .overground:          return Color(hex: "EE7C0E")
        case .dlr:                 return Color(hex: "00A4A7")
        case .nationalRail:        return Color(hex: "AE2029")
        default:                   return Color(hex: "414141")
        }
    }
}
```

### `core/Models/Disruption.swift`
```swift
struct Disruption: Identifiable {
    let id: UUID = UUID()
    let line: TfLLine
    let severity: Route.LineStatus
    let summary: String
}
```

### `core/Models/UserProfile.swift`
```swift
import Foundation

struct UserProfile: Codable {
    var firstName: String
    var useSerif: Bool
    var accentStyle: AccentStyle
    var mapsProvider: MapsProvider
    var locations: [SavedLocation]
    var usualRoutes: [RoutePair: UsualRoute]

    enum MapsProvider: String, Codable, CaseIterable {
        case apple, google, openStreetMap

        var displayName: String {
            switch self {
            case .apple:        return "Apple Maps"
            case .google:       return "Google Maps"
            case .openStreetMap: return "OpenStreetMap"
            }
        }

        var privacySummary: String {
            switch self {
            case .apple:        return "Private. On-device where possible. No extra sign-in."
            case .google:       return "Detailed London data. Subject to Google's privacy policy."
            case .openStreetMap: return "Open source. No tracking. Community data."
            }
        }
    }
}

struct RoutePair: Codable, Hashable {
    let fromID: UUID
    let toID: UUID
}

struct UsualRoute: Codable {
    let routePair: RoutePair
    let legs: [RouteLeg]       // Stored legs from TfL suggestion or manual override
    let activeDays: Set<Weekday>
    let departureTime: DateComponents  // Hour + minute only
    let notificationLeadMinutes: Int   // 5 / 10 / 15 / 20 / 30
}

enum Weekday: Int, Codable, CaseIterable {
    case monday = 2, tuesday, wednesday, thursday, friday, saturday, sunday
}
```

---

## 6. Onboarding Feature

Path: `features/onboarding/`

### 6.1 Flow Structure

`features/onboarding/views/OnboardingFlowView.swift`

Manages the 11-step sequence. Uses a single `@State var step: OnboardingStep` and a `ZStack` for transitions. Each step is a full-screen child view. The `OnboardingFlowViewModel` holds all in-progress data until the flow completes, at which point it is persisted and `AppState.completeOnboarding()` is called.

The progress bar is a `GeometryReader`-based line that fills proportionally to `step.progressFraction`.

```swift
enum OnboardingStep: Int, CaseIterable {
    case welcome        = 1
    case name           = 2
    case typeface       = 3
    case accentColour   = 4
    case locationPerm   = 5
    case locations      = 6
    case mapsProvider   = 7
    case usualCommute   = 8
    case usualTimes     = 9
    case paceLearning   = 10
    case liveActivities = 11
    case done           = 12

    var progressFraction: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count)
    }

    /// Steps that cannot be skipped
    var isRequired: Bool {
        [.welcome, .name, .typeface, .accentColour, .locations, .mapsProvider, .usualCommute].contains(self)
    }
}
```

Step transitions: slide in from trailing on advance, from leading on back. Use `matchedGeometryEffect` on the progress bar fill. Respects reduce motion (crossfade only).

### 6.2 OnboardingFlowViewModel

`features/onboarding/view-models/OnboardingFlowViewModel.swift`

```swift
@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var firstName: String = ""
    @Published var useSerif: Bool = false
    @Published var accentStyle: AccentStyle = .solid(.blue)
    @Published var homeLocation: SavedLocation?
    @Published var workLocation: SavedLocation?
    @Published var otherLocation: SavedLocation?
    @Published var mapsProvider: UserProfile.MapsProvider = .apple
    @Published var selectedUsualRoute: UsualRoute?
    @Published var enablePaceLearning: Bool = false
    @Published var enableLiveActivities: Bool = false

    // In-progress state for usual commute step
    @Published var suggestedRoutes: [Route] = []
    @Published var isFetchingSuggestions: Bool = false

    private let routeProvider: RouteProviding

    init(routeProvider: RouteProviding = MockRouteProvider()) {
        self.routeProvider = routeProvider
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentStep = next
        }
    }

    func back() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentStep = prev
        }
    }

    func fetchRouteSuggestions() async {
        guard let home = homeLocation, let work = workLocation else { return }
        isFetchingSuggestions = true
        defer { isFetchingSuggestions = false }
        do {
            suggestedRoutes = try await routeProvider.fetchRoutes(from: home, to: work)
        } catch {
            suggestedRoutes = []
        }
    }

    func completeOnboarding(appState: AppState) {
        appState.setFont(serif: useSerif)
        appState.setAccent(accentStyle)
        appState.completeOnboarding()
        // TODO: Persist UserProfile via SwiftData in v1 TfL integration slice
    }
}
```

### 6.3 Individual Step Views

Create one file per step in `features/onboarding/views/steps/`. Each step view takes a binding to the view model and a closure for advance/back actions.

**File list (create all, even if placeholder):**
- `OnboardingWelcomeView.swift`
- `OnboardingNameView.swift`
- `OnboardingTypefaceView.swift`
- `OnboardingAccentColourView.swift`
- `OnboardingLocationPermView.swift`
- `OnboardingLocationsView.swift`
- `OnboardingMapsProviderView.swift`
- `OnboardingUsualCommuteView.swift`
- `OnboardingUsualTimesView.swift`
- `OnboardingPaceLearningView.swift`
- `OnboardingLiveActivitiesView.swift`
- `OnboardingDoneView.swift`

#### Layout rules for all step views:

```
VStack(alignment: .leading, spacing: 0) {
    // Headline — 34pt, left-aligned, max 80% width, mixed type treatment
    // Subheadline if needed — 17pt, text.secondary
    Spacer()
    // Main content (field / picker / options)
    Spacer()
    // CTA button (primary) + Skip link (if step is optional)
}
.padding(.horizontal, 24)
.padding(.top, 16)    // below progress bar
.padding(.bottom, 32) // above home indicator
.background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
```

#### Headline typographic treatment (used on every step):

Create a reusable component `core/Components/OnboardingHeadline.swift`:

```swift
struct OnboardingHeadline: View {
    let parts: [HeadlinePart]
    let useSerif: Bool

    enum HeadlinePart {
        case plain(String)
        case serif(String)   // italic serif — user name, destination
    }

    var body: some View {
        // Render as a single Text with concatenated attributed substrings
        // Plain parts: SF Pro 34pt regular
        // Serif parts: Playfair Display Italic 34pt (or SF Pro italic if useSerif == false)
        parts.reduce(Text("")) { result, part in
            switch part {
            case .plain(let s):
                return result + Text(s)
                    .font(.system(size: 34, weight: .regular, design: .default))
            case .serif(let s):
                let font: Font = useSerif
                    ? .playfairItalic(size: 34)
                    : .system(size: 34, weight: .regular, design: .default).italic()
                return result + Text(s).font(font)
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.80, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
```

#### Primary CTA Button:

Create `core/Components/CommutePrimaryButton.swift`:

```swift
struct CommutePrimaryButton: View {
    let label: String
    let accentStyle: AccentStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var accentBackground: some View {
        switch accentStyle {
        case .solid(let s):
            s.color
        case .gradient(let g):
            LinearGradient(stops: g.stops, startPoint: .leading, endPoint: .trailing)
        }
    }
}
```

### 6.4 Typeface Step Detail

`OnboardingTypefaceView.swift` displays two large option rows. Each row contains:
- A live preview of the string `"[firstName], your Elizabeth line leaves in 4 mins."` rendered with the mixed type treatment
- A label ("Sans" or "Serif") in `text.secondary`

Selecting a row updates `viewModel.useSerif` immediately. The preview updates with a 150ms crossfade. A single CTA ("Continue") advances the flow.

### 6.5 Accent Colour Step Detail

`OnboardingAccentColourView.swift`:

- Two-section `ScrollView(.horizontal)`: solid colours row, then gradient row
- Each swatch is a `Circle`, 52pt diameter, 12pt spacing
- Selected swatch has a 2pt white ring inset, 1pt `text.secondary` outer ring
- Live preview of the typeface sample string beneath the swatches — the accent colour underlines the destination word ("Elizabeth line")
- The underline is drawn as a `Rectangle` overlay, 1.5pt height, offset 2pt below the text baseline

Gradient swatches display as a `LinearGradient` fill on the circle.

### 6.6 Usual Commute Step Detail

`OnboardingUsualCommuteView.swift`:

On appear: call `viewModel.fetchRouteSuggestions()`. While loading: show three placeholder rows with `.redacted(reason: .placeholder)` shimmer.

Each suggested route is rendered using the same `RouteRowView` component used in the main route results screen (see Section 7.3). Tapping a row selects it as the Usual Route.

At the bottom: a secondary text button "Mine's different →". Tapping it pushes `OnboardingManualRouteView` (see below).

`OnboardingManualRouteView.swift`:

A guided 5-step sub-flow within this step. Uses a local `@State var manualStep` (departure station → line → direction → optional change → arrival station). Each sub-step shows a search field with mock autocomplete results. The user cannot proceed to the next sub-step without a valid selection — invalid states are impossible to reach.

---

## 7. Home Feature

Path: `features/home/`

### 7.1 HomeView

`features/home/views/HomeView.swift`

The root view after onboarding. Contains:

1. **Status line** (top, `text.secondary`, 13pt): current time + a one-word service status for the user's usual route. e.g. `"08:32 · Good service"`. Right-aligned.
2. **Commute button** (vertically centred, prominently sized).
3. **Settings gear** (top right, SF Symbol `gearshape`, `text.secondary`).

The screen is intentionally sparse. No list. No cards. The Commute button is the entire product.

### 7.2 CommuteButton

`features/home/views/CommuteButton.swift`

```
[ Head to Work ]
```

- Label: contextual (see product spec 5.1). Default `"Commute"`.
- Size: full-width minus 48pt horizontal margins. Height: 64pt.
- Background: accent colour (solid or gradient). Corner radius: 16pt.
- Text: 17pt semibold, white.
- Idle animation: scale pulse 1.0 → 1.015 → 1.0, 3s loop, ease-in-out. Off when `isReduceMotionEnabled`.
- On tap: triggers route results sheet. Label fades out (150ms), sheet rises with standard spring.

### 7.3 RouteResultsView

`features/home/views/RouteResultsView.swift`

Presented as a `.sheet` from `HomeView`. `detents: [.large]`. No drag indicator.

**Header:**
```swift
OnboardingHeadline(parts: [
    .serif(firstName + ","),
    .plain(" here are your options for today's journey to "),
    .serif(destination.displayName + ".")
], useSerif: useSerif)
```

Accent-coloured underline on the destination word — implemented as a `ZStack` overlay on the serif `Text` portion.

**Disruption line (conditional):**
Plain `Text` in `statusWarning` or `statusDisrupted`. Appears with 200ms fade. No icon.

**Route rows:**
`LazyVStack(spacing: 0)` containing three `RouteRowView` instances.

`RouteRowView` must be a standalone component at `core/Components/RouteRowView.swift` — shared between the home feature and onboarding.

### 7.4 RouteRowView

`core/Components/RouteRowView.swift`

```swift
struct RouteRowView: View {
    let route: Route
    let isExpanded: Bool
    let onTap: () -> Void
}
```

**Compact state:**

```
Via the Elizabeth line          22 mins
🚶 → [Elizabeth] → 🚶
```

- Top line: `HStack` — summary text (leading, `routeSummary` font) + total time (trailing, `routeTime` font, `.monospacedDigit()`)
- Bottom line: icon strip — `HStack(spacing: 8)` of walk icons + `LineChipView` components + `Text("→")` separators

Vertical padding: 16pt top and bottom.

**Expanded state (animated):**

Reveals beneath the icon strip:
- Departure time: `"Departs [station] at [time]"` — `journeyDetail` font
- Platform if non-nil: `"Platform [n]"` — `secondary` font, `text.secondary` colour
- Each transit leg: line name, direction, stop count, alighting station
- Walking leg detail with distance
- Status dot + label for each transit leg
- Next two departures in a `HStack`, `secondary` font, `text.secondary`

Expansion animation: `withAnimation(.spring(response: 0.35, dampingFraction: 0.75))` on a `@State var isExpanded` bool. Content fades in with `.transition(.opacity.combined(with: .move(edge: .top)))`.

Only one row expanded at a time — managed by `@State var expandedRouteID: UUID?` in `RouteResultsView`.

### 7.5 LineChipView

`core/Components/LineChipView.swift`

```swift
struct LineChipView: View {
    let line: TfLLine

    var body: some View {
        Text(line.displayName)
            .font(Theme.Fonts.lineChip)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(line.brandColor)
            .clipShape(Capsule())
    }
}
```

### 7.6 HomeViewModel

`features/home/view-models/HomeViewModel.swift`

```swift
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var isLoading: Bool = false
    @Published var disruptions: [Disruption] = []
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    private let routeProvider: RouteProviding
    private let disruptionProvider: DisruptionProviding

    init(
        routeProvider: RouteProviding = MockRouteProvider(),
        disruptionProvider: DisruptionProviding = MockDisruptionProvider()
    ) {
        self.routeProvider = routeProvider
        self.disruptionProvider = disruptionProvider
    }

    func loadRoutes(from: SavedLocation, to: SavedLocation) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let routes = routeProvider.fetchRoutes(from: from, to: to)
            async let disruptions = disruptionProvider.fetchDisruptions(for: TfLLine.allCases)
            self.routes = try await routes
            self.disruptions = try await disruptions
            self.lastUpdated = Date()
        } catch {
            errorMessage = "Couldn't load routes. Pull down to try again."
        }
    }
}
```

---

## 8. Settings Feature (Stub Only)

Path: `features/settings/`

For this slice: a single `SettingsView.swift` with placeholder content. Must be reachable from the gear icon on `HomeView`. No functionality beyond navigation and a "Reset onboarding" debug button (debug builds only).

Do not build the full settings feature in this slice.

---

## 9. File Creation Checklist

The agent must create every file in this list. Check off as you go.

**Step 0 — Theme**
- [ ] `core/Theme.swift` — updated per Section 2
- [ ] `core/Extensions/Color+Hex.swift`
- [ ] `core/Extensions/Font+Serif.swift`
- [ ] `core/Resources/Fonts/PlayfairDisplay-Italic.ttf`
- [ ] `core/Resources/Fonts/OFL.txt`

**App shell**
- [ ] `app/CommuteApp.swift`
- [ ] `app/AppState.swift`
- [ ] `app/AppRouter.swift`

**Core models**
- [ ] `core/Models/SavedLocation.swift`
- [ ] `core/Models/Route.swift`
- [ ] `core/Models/TfLLine.swift`
- [ ] `core/Models/Disruption.swift`
- [ ] `core/Models/UserProfile.swift`

**Services**
- [ ] `core/Services/RouteProviding.swift`
- [ ] `core/Services/DisruptionProviding.swift`

**Mocks**
- [ ] `core/Mocks/MockRouteProvider.swift`
- [ ] `core/Mocks/MockDisruptionProvider.swift`
- [ ] `core/Mocks/Route+Mock.swift`

**Shared components**
- [ ] `core/Components/OnboardingHeadline.swift`
- [ ] `core/Components/CommutePrimaryButton.swift`
- [ ] `core/Components/RouteRowView.swift`
- [ ] `core/Components/LineChipView.swift`

**Onboarding**
- [ ] `features/onboarding/views/OnboardingFlowView.swift`
- [ ] `features/onboarding/views/steps/OnboardingWelcomeView.swift`
- [ ] `features/onboarding/views/steps/OnboardingNameView.swift`
- [ ] `features/onboarding/views/steps/OnboardingTypefaceView.swift`
- [ ] `features/onboarding/views/steps/OnboardingAccentColourView.swift`
- [ ] `features/onboarding/views/steps/OnboardingLocationPermView.swift`
- [ ] `features/onboarding/views/steps/OnboardingLocationsView.swift`
- [ ] `features/onboarding/views/steps/OnboardingMapsProviderView.swift`
- [ ] `features/onboarding/views/steps/OnboardingUsualCommuteView.swift`
- [ ] `features/onboarding/views/steps/OnboardingManualRouteView.swift`
- [ ] `features/onboarding/views/steps/OnboardingUsualTimesView.swift`
- [ ] `features/onboarding/views/steps/OnboardingPaceLearningView.swift`
- [ ] `features/onboarding/views/steps/OnboardingLiveActivitiesView.swift`
- [ ] `features/onboarding/views/steps/OnboardingDoneView.swift`
- [ ] `features/onboarding/view-models/OnboardingFlowViewModel.swift`

**Home**
- [ ] `features/home/views/HomeView.swift`
- [ ] `features/home/views/CommuteButton.swift`
- [ ] `features/home/views/RouteResultsView.swift`
- [ ] `features/home/view-models/HomeViewModel.swift`

**Settings (stub)**
- [ ] `features/settings/views/SettingsView.swift`

---

## 10. Out of Scope for This Slice

Do not build any of the following. If the agent encounters a reference to one of these, stub it with a `// TODO:` comment and move on.

- TfL API calls (all data is mock)
- CoreLocation / location permission request (stub the UI, do not call `CLLocationManager`)
- `UNUserNotificationCenter` (stub notification permission UI, do not schedule)
- `ActivityKit` / Live Activities
- `BGTaskScheduler`
- `SwiftData` persistence (use `UserDefaults` for `AppState` only, as specified)
- Google Maps SDK
- OSRM / OpenStreetMap routing
- Pace learning engine
- Automation scheduling logic
- Settings (functional)
- `MKMapView` in route results (the map is deferred — route rows only in v0)

---

## 11. Code Quality Rules

These apply to every file in this slice.

- **SwiftUI only.** No `UIViewRepresentable` wrappers unless unavoidable (they are not in this slice).
- **No force unwraps** (`!`). Use `guard let`, `if let`, or provide a safe default.
- **No `print()` statements** in committed code. Use `#if DEBUG` blocks if logging is needed.
- **SwiftLint** must pass with zero warnings. The `.swiftlint.yml` in the repo root is the authority.
- **All `async` functions** called from SwiftUI must be dispatched via `.task {}` or `Task { }` inside a `@MainActor` context. No `DispatchQueue.main.async`.
- **`@EnvironmentObject`** is used only for `AppState`. Feature-level state is `@StateObject` / `@ObservedObject`.
- **No magic numbers** in layout. All spacing values come from multiples of 4. Name them if used more than once:
  ```swift
  private enum Layout {
      static let horizontalPadding: CGFloat = 24
      static let buttonHeight: CGFloat = 64
  }
  ```
- **Accessibility:** Every interactive element must have `.accessibilityLabel()` and `.accessibilityHint()` set. Every image must have `.accessibilityLabel()` or `.accessibilityHidden(true)`.
- **Reduce Motion:** Every animation block must check `@Environment(\.accessibilityReduceMotion)` and substitute a crossfade when true.

---

## 12. Review Criteria

Before marking this slice complete, the following must all be true:

- [ ] Xcode builds with zero errors and zero warnings on iPhone 15 Pro simulator (iOS 17)
- [ ] SwiftLint passes with zero warnings
- [ ] Full onboarding flow navigates start to finish with no crashes
- [ ] Typeface preview renders correctly for both Sans and Serif options
- [ ] Accent colour live preview updates correctly for all 13 options (8 solid + 5 gradient)
- [ ] Commute button appears on home screen after onboarding completes
- [ ] Route results sheet presents with 3 mock routes
- [ ] Route rows expand and collapse correctly; only one expanded at a time
- [ ] Disruption text renders in correct colour; absent when no disruption
- [ ] All TfL line chip colours match official brand palette
- [ ] Reduce Motion: all animations degrade to crossfade
- [ ] VoiceOver: all interactive elements are reachable and labelled
- [ ] No real API calls made at any point (confirmed by running with network access disabled)
- [ ] Onboarding state persists across app restarts (kill and relaunch mid-flow resumes correctly)

---

*This document governs the v0 scaffold slice only. The next slice will introduce TfL API integration, CoreLocation, and SwiftData persistence. Those specs will be written separately before that work begins.*