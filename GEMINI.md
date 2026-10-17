# SwiftUI Best Practices and Guidelines

## Project Structure
- **Sources**: Contains the main application files (`FinFlow/Sources`).
  - **App**: Main application entry point and root navigation (`FinFlowApp.swift`, `ContentView.swift`).
  - **Views**: Divided into feature sections (`Home`, `Transactions`, `Settings`, `Onboarding`, `Main`), with extracted reusable subviews per file.
  - **Shared**: Design system (`Theme.swift`) and reusable components/modifiers (`Components/`).
  - **Models**: SwiftData `@Model` classes and domain value types (`Account.swift`, `Transaction.swift`, `TransactionType.swift`, `AccountColor.swift`, `OnboardingStep.swift`).
  - **ViewModels**: `@Observable` view models managing presentation state (`OnboardingViewModel.swift`, `TransactionsViewModel.swift`).
  - **Services**: Domain and persistence services (`TransactionService.swift`).
  - **Utilities**: Shared formatters, date calculations, and helper functions (`CurrencyFormatter.swift`, `DateUtils.swift`).
- **Resources**:
  - **Assets**: Images and colors (`Assets.xcassets`).
  - **Localization**: Localized strings.
  - **Fonts**: Custom fonts.
- **Tests**:
  - **UnitTests**: Unit testing using Swift Testing (`@Test`, `#expect`).
  - **UITests**: UI testing using XCTest.

## SwiftUI UI Design & HIG Rules
1. **Use Modern Built-in Components**: Utilize SwiftUI's native elements like `List`, `NavigationStack`, `Tab` (`TabView`), `ContentUnavailableView`, and `SF Symbols` for an iOS-consistent look.
2. **Master Layout Tools**: Employ `VStack`, `HStack`, `ZStack`, `Spacer`, and `LazyVGrid` / `LazyHGrid` for responsive designs; use `.scrollClipDisabled()` instead of negative padding hacks.
3. **Liquid Glass & Visual Flair (iOS 26+)**: Enhance UIs with native `.glassEffect(_:in:)` and `GlassEffectContainer` (wrapped around grouped glass elements only), providing Material fallbacks via `glassEffectWithFallback` and `prominentGlassEffectWithFallback`. Always use `.animation(_:value:)` with an explicit value parameter.
4. **Accessibility & Dynamic Type**:
   - Use Dynamic Type fonts (`Font.system(.body)`, etc.) and `@ScaledMetric` for custom sizes; never hardcode unscaled font sizes.
   - Use `Button` instead of `.onTapGesture` for interactive elements, enforce ≥ 44×44pt tap targets, and provide `.accessibilityLabel` for icon-only controls.
   - Respect `@Environment(\.accessibilityReduceMotion)` for continuous or particle animations.

## Coding Standards
- **Single Type Per File**: Place each primary `struct`, `class`, or `enum` in its own Swift file.
- **Value Semantics & Immutability**: Prefer `struct` and `let` properties where mutation is not required.
- **Naming Conventions**: Use `camelCase` for properties, variables, and functions, and `PascalCase` for types (`View`, `@Model`, `enum`, `struct`).
- **Swift 6 Concurrency**: Respect `@MainActor` default actor isolation; mark persisted `Codable` enums `nonisolated` and use structured concurrency (`Task`, `Task.sleep(for:)`) instead of `DispatchQueue`.

## State Management & Performance Optimization
- **Observation**: Use `@Observable` classes owned with `@State private var` and passed via `@Bindable` or `@Environment`.
- **Single-Pass View Evaluation**: Compute derived collections (such as monthly filtered transactions and summaries) once per `body` pass rather than repeatedly inside multiple sub-properties.
- **Stable Identity**: Ensure `ForEach` items use stable `Identifiable` IDs (including deterministic UUIDs for virtual recurring transactions).
- **Cached Formatters**: Centralize `NumberFormatter` and `DateFormatter` instances in `Sources/Utilities/` instead of instantiating them inside view bodies or list rows.

## Error Handling & Safety
- **No Silent Data Loss**: Always present a `.confirmationDialog` before destructive actions (deleting accounts, deleting transactions, or wiping app data).
- **Do Not Swallow Errors**: Surface persistence errors to the user via `.alert` rather than printing to the console, and avoid force unwrapping (`!`).
