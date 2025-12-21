# Copilot Instructions for HuselenClient

## Project Overview
- **HuselenClient** is a SwiftUI iOS/macOS app structured with MVVM (Model-View-ViewModel) pattern.
- Major domains: Authentication, Home, Check-In, Meal Logging, Weight Tracking, Profile, Onboarding, and Manager/PT features.
- Data models are in `Models/`, view logic in `ViewModels/`, and UI in `Views/` (subfolders by feature).
- Supabase is used for backend integration (see `Supabase/SupabaseConfig.swift`).

## Key Architectural Patterns
- **MVVM**: Each feature has a ViewModel (e.g., `HomeViewModel.swift`) and corresponding View(s) (e.g., `HomeView.swift`).
- **Navigation**: Main navigation is handled by `MainTabView.swift`, `ManagerTabView.swift`, and `PTTabView.swift`.
- **State Management**: Uses `@StateObject` and `@ObservedObject` for ViewModels.
- **Preview Content**: Use `Preview Content/` for SwiftUI previews.

## Developer Workflows
- **Build & Run**: Use Xcode (open `HuselenClient.xcodeproj`).
- **Testing**: Tests are in `HuselenClientTests/` and `HuselenClientUITests/`. Run via Xcode test navigator or `Cmd+U`.
- **Assets**: Images and colors in `Assets.xcassets/`.
- **Entitlements**: Managed in `HuselenClient.entitlements`.

## Project-Specific Conventions
- **ViewModel Naming**: Always ends with `ViewModel` and lives in `ViewModels/`.
- **View Organization**: Views are grouped by feature in `Views/` subfolders.
- **Model Simplicity**: Models are plain Swift structs/classes, no CoreData/Realm.
- **Supabase**: All backend config and calls are centralized in `Supabase/`.
- **No Storyboards**: 100% SwiftUI, no UIKit or storyboards.

## Integration Points
- **Supabase**: All backend communication via `SupabaseConfig.swift`.
- **No 3rd-party UI frameworks**: Only SwiftUI and native Apple frameworks.

## Examples
- To add a new feature, create a Model (if needed), a ViewModel in `ViewModels/`, and Views in the appropriate `Views/` subfolder.
- For backend calls, add logic to `SupabaseConfig.swift` or call its methods from ViewModels.

## References
- Main entry: `HuselenClientApp.swift`
- Navigation: `Views/Main/MainTabView.swift`, `Views/Manager/ManagerTabView.swift`, `Views/PT/PTTabView.swift`
- Backend: `Supabase/SupabaseConfig.swift`
- Example ViewModel: `ViewModels/HomeViewModel.swift`
- Example Model: `Models/UserProfile.swift`

---

If you are unsure about a pattern or workflow, check for similar files in the relevant folder and follow their structure.
