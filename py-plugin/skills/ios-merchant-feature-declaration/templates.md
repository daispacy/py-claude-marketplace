# iOS Feature Declaration - Code Templates

All code templates for declaring a new iOS feature.

---

## Template 1: Feature.swift - Add Feature Case

**Location in file:** Group by category (Home, Side menu, Other, Statistics, etc.)

```swift
// [CategoryComment] (e.g., // Balance)
case [featureName]  // [vietnameseDescription]
```

**Example:**
```swift
// Balance
case balanceHistory  // Lịch sử số dư
```

**Placement:** Add alphabetically within the appropriate section.

---

## Template 2: Feature.swift - Add Permission Code

**Location:** Inside `public var code: Int?` computed property

```swift
case .[featureName]:
    return [permissionCode]
```

**Example (with permission):**
```swift
case .balanceHistory:
    return 32119
```

**Example (no permission):**
```swift
// No addition needed - returns nil in default case
```

**Placement:** Add alphabetically within the switch statement.

---

## Template 3: Feature.swift - Add FeatureInfo Mapping

**Location:** Inside `public func getInfo() -> FeatureInfo?` method

```swift
case .[featureName]:
    return .[featureName]
```

**Example:**
```swift
case .balanceHistory:
    return .balanceHistory
```

**Placement:** Add alphabetically within the switch statement, before the default case.

---

## Template 4: Feature.swift - Add to Category Array

**Location:** Static category arrays

```swift
public static var [categoryName]: [Feature] {
    [...existingFeatures, .[featureName]]
}
```

**Example:**
```swift
public static var leftAccountCategories: [Feature] {
    [.walletInfo, .bankAccount, .palHistory, .balanceHistory]  // ✅ Added
}
```

**Available Categories:**
- `counterService` - Counter services
- `onlineServices` - Online services
- `utilityServices` - Utility services
- `leftAccountCategories` - Left account section
- `leftCounterCategories` - Left counter section
- `leftOnlineCategories` - Left online section
- `leftUtilityCategories` - Left utility section
- `leftInstallmentConversionCategories` - Left installment section
- `rightCounterCategories` - Right counter section
- `rightOnlineCategories` - Right online section
- `rightUtilityCategories` - Right utility section

---

## Template 5: Feature.swift - Add Identifier

**Location:** Inside `public var identifier: String` computed property

```swift
case .[featureName]: "[featureName]"
```

**Example:**
```swift
case .balanceHistory: "balanceHistory"
```

**Placement:** Add alphabetically within the switch statement.

---

## Template 6: FeatureInfo.swift - Add Static Property

**Location:** Inside `public struct FeatureInfo`

```swift
static var [featureName]: FeatureInfo {
    FeatureInfo(
        imageName: "[iconName]",
        title: "menu.label.[feature-name-kebab]".localized
    )
}
```

**With favorite title:**
```swift
static var [featureName]: FeatureInfo {
    FeatureInfo(
        imageName: "[iconName]",
        title: "menu.label.[feature-name-kebab]".localized,
        favoriteTitle: "menu.label.[feature-name-kebab]-favorite".localized
    )
}
```

**Example:**
```swift
static var balanceHistory: FeatureInfo {
    FeatureInfo(
        imageName: "balance-history-icon",
        title: "menu.label.balance-history".localized
    )
}
```

**Placement:** Add alphabetically among other static properties.

---

## Template 7: Localizable.strings - Vietnamese

**File:** `PayooMerchant/Resources/Localization/vi.lproj/Localizable.strings`

```strings
/* [Feature Name] */
"menu.label.[feature-name-kebab]" = "[Vietnamese Description]";
"home.label.feature-[feature-name-kebab]" = "[Vietnamese Description]";
```

**With favorite:**
```strings
/* [Feature Name] */
"menu.label.[feature-name-kebab]" = "[Vietnamese Description]";
"menu.label.[feature-name-kebab]-favorite" = "[Short Vietnamese]";
"home.label.feature-[feature-name-kebab]" = "[Vietnamese Description]";
```

**Example:**
```strings
/* Balance History */
"menu.label.balance-history" = "Lịch sử số dư";
"home.label.feature-balance-history" = "Lịch sử số dư";
```

**Placement:** Append to end of file with a comment header.

---

## Template 8: Localizable.strings - English

**File:** `PayooMerchant/Resources/Localization/en.lproj/Localizable.strings`

```strings
/* [Feature Name] */
"menu.label.[feature-name-kebab]" = "[English Description]";
"home.label.feature-[feature-name-kebab]" = "[English Description]";
```

**With favorite:**
```strings
/* [Feature Name] */
"menu.label.[feature-name-kebab]" = "[English Description]";
"menu.label.[feature-name-kebab]-favorite" = "[Short English]";
"home.label.feature-[feature-name-kebab]" = "[English Description]";
```

**Example:**
```strings
/* Balance History */
"menu.label.balance-history" = "Balance History";
"home.label.feature-balance-history" = "Balance History";
```

**Placement:** Append to end of file with a comment header.

---

## Template 9: ScreenID.swift - Add Deep Link Case

**File:** `Domain/Model/Setting/ScreenID.swift`

**Location:** Inside `public enum ScreenID: String, CaseIterable`

```swift
// [Feature Category]
case [featureName] = "[deepLinkPath]"
```

**Example:**
```swift
// Balance
case balanceHistory = "balance/history"
case balanceHistoryDetail = "balance/history/detail"
```

**Placement:** Add in appropriate category section, alphabetically.

---

## Template 10: Route.swift - Add Route Case

**File:** `PayooMerchant/Library/DeepLink/Route.swift`

**Step 1:** Add enum case
```swift
enum Route {
    // ... existing cases
    case [featureName]
    case [featureName]Detail([ItemType])  // If has detail view
}
```

**Step 2:** Add URL mapping in `init?(url: URL)`
```swift
init?(url: URL) {
    switch url {
    // ... existing cases

    case ScreenID.[featureName].url:
        self = .[featureName]

    // ... rest
    }
}
```

**Example:**
```swift
// Step 1: Enum case
enum Route {
    case balanceHistory
    case balanceHistoryDetail(BalanceHistoryItem)
}

// Step 2: URL mapping
init?(url: URL) {
    switch url {
    case ScreenID.balanceHistory.url:
        self = .balanceHistory

    default:
        if url.absoluteString.contains(ScreenID.balanceHistoryDetail.url.absoluteString),
           let params = url.queryParameters,
           let itemId = params["id"] {
            // Parse and create route
            self = .balanceHistoryDetail(item)
        } else {
            return nil
        }
    }
}
```

---

## Template 11: ViewControllerFactory - Factory Method

**File:** `PayooMerchant/Library/Core/ViewControllerFactory.swift`

```swift
extension ViewControllerFactory {
    func make[FeatureName]Controller() -> [FeatureName]Controller {
        let controller = [FeatureName]Controller.instantiate()
        controller.viewModel = DependencyContainer.shared.provide([FeatureName]ViewModel.self)
        return controller
    }
}
```

**With parameters:**
```swift
extension ViewControllerFactory {
    func make[FeatureName]DetailController(item: [ItemType]) -> [FeatureName]DetailController {
        let controller = [FeatureName]DetailController.instantiate()
        controller.viewModel = DependencyContainer.shared.provide([FeatureName]DetailViewModel.self)
        controller.item = item
        return controller
    }
}
```

**Example:**
```swift
extension ViewControllerFactory {
    func makeBalanceHistoryController() -> BalanceHistoryController {
        let controller = BalanceHistoryController.instantiate()
        controller.viewModel = DependencyContainer.shared.provide(BalanceHistoryViewModel.self)
        return controller
    }
}
```

---

## Template 12: DependencyContainer - ViewModel Registration

**File:** `PayooMerchant/Library/Core/DependencyContainer.swift`

```swift
// Register [Feature Name] ViewModel
container.register([FeatureName]ViewModel.self) { resolver in
    [FeatureName]ViewModel(
        [featureName]UC: resolver.resolve([FeatureName]UseCaseType.self)!,
        navigator: resolver.resolve([FeatureName]NavigatorType.self)!
    )
}
```

**Example:**
```swift
// Register Balance History ViewModel
container.register(BalanceHistoryViewModel.self) { resolver in
    BalanceHistoryViewModel(
        balanceHistoryUC: resolver.resolve(BalanceHistoryUseCaseType.self)!,
        navigator: resolver.resolve(BalanceHistoryNavigatorType.self)!
    )
}
```

**Placement:** Add in the ViewModel registration section (usually `setupViewModels()` method).

---

## Template 13: Navigator Extension - Deep Link Navigation

**File:** Create new file `PayooMerchant/Controllers/[Feature]/Navigator+[Feature].swift`

```swift
import Foundation
import Domain

// MARK: - Protocol
protocol [FeatureName]NavigatorType {
    func navigate(to destination: [FeatureName]Destination)
}

// MARK: - Destinations
enum [FeatureName]Destination {
    case [featureName]Detail(item: [ItemType])
    // Add more destinations as needed
}

// MARK: - Navigator Extension
extension Navigator: [FeatureName]NavigatorType {
    func navigate(to destination: [FeatureName]Destination) {
        switch destination {
        case .[featureName]Detail(let item):
            let controller = viewControllerFactory.make[FeatureName]DetailController(item: item)
            push(controller)
        }
    }
}
```

**Example:**
```swift
import Foundation
import Domain

// MARK: - Protocol
protocol BalanceHistoryNavigatorType {
    func navigate(to destination: BalanceHistoryDestination)
}

// MARK: - Destinations
enum BalanceHistoryDestination {
    case balanceHistoryDetail(item: BalanceHistoryItem)
}

// MARK: - Navigator Extension
extension Navigator: BalanceHistoryNavigatorType {
    func navigate(to destination: BalanceHistoryDestination) {
        switch destination {
        case .balanceHistoryDetail(let item):
            let controller = viewControllerFactory.makeBalanceHistoryDetailController(item: item)
            push(controller)
        }
    }
}
```

---

## Template 14: DeepLinkNavigator - Route Handling

**File:** `PayooMerchant/Library/DeepLink/DeepLinkNavigator.swift`

**Add to `navigate(to route: Route)` method:**

```swift
func navigate(to route: Route) {
    switch route {
    // ... existing cases

    case .[featureName]:
        let controller = viewControllerFactory.make[FeatureName]Controller()
        navigator.push(controller)

    case .[featureName]Detail(let item):
        let controller = viewControllerFactory.make[FeatureName]DetailController(item: item)
        navigator.push(controller)

    // ... rest
    }
}
```

**Example:**
```swift
func navigate(to route: Route) {
    switch route {
    case .balanceHistory:
        let controller = viewControllerFactory.makeBalanceHistoryController()
        navigator.push(controller)

    case .balanceHistoryDetail(let item):
        let controller = viewControllerFactory.makeBalanceHistoryDetailController(item: item)
        navigator.push(controller)
    }
}
```

---

## Template 15: DeepLinkNavigator - Add Route Case (CRITICAL)

**File:** `PayooMerchant/Library/DeepLink/DeepLinkNavigator.swift`

**Add to `getViewController(from destination:)` method before closing brace:**

```swift
case .[featureName]:
    // TODO: Implement [FeatureName]Controller
    // return viewControllerFactory.make[FeatureName]Controller()
    return viewControllerFactory.makeHomeViewController()
```

**Example:**
```swift
case .payLater:
    // TODO: Implement PayLaterController
    // return viewControllerFactory.makePayLaterController()
    return viewControllerFactory.makeHomeViewController()
```

**Placement:** Add before the closing brace of the switch statement (around line 255).

---

## Template 16: Feature+Ext - Add Navigation Bar Title (CRITICAL)

**File:** `PayooMerchant/Models/Feature+Ext.swift`

**Option A: Feature has navigation bar title**
```swift
case .[featureName]:
    return L10n.[featureName]NavigationTitle()
```

**Option B: Feature has no navigation bar title (add to nil-returning cases)**
```swift
case .existingCase1,
     .existingCase2,
     ...,
     .[featureName]:
    return nil
```

**Example (no navigation bar title):**
```swift
case .configurationSmartOTP,
     .getSmartOTPCode,
     .payLater:  // ✅ ADDED
    return nil
```

**Placement:** Add to the `navigationBarTitle` computed property's switch statement.

---

## Template 17: AppDelegateViewModel - Add Route Filtering (CRITICAL)

**File:** `PayooMerchant/AppDelegateViewModel.swift`

**Option A: Feature requires permission check**
```swift
case .[featureName]:
    return settings.supportedFeatures.contains(.[featureName])
```

**Option B: No permission required (add to true-returning cases)**
```swift
case .notifications,
     .mmsTransactionsHistory,
     ...,
     .[featureName]:
    return true
```

**Example (no permission):**
```swift
case .notifications,
     .mmsTransactionsHistory,
     .login,
     .home,
     .qrCodePayment,
     .dashboardSupportCenter,
     .supportCenterHistory,
     .supportCenterThread,
     .paymentRequestHistory,
     .installmentConversionManager,
     .refundRequestManagement,
     .smartOTP,
     .configurationSmartOTP,
     .setupSmartOTP,
     .payLater:  // ✅ ADDED
    return true
```

**Placement:** Add to the route filtering switch statement (around line 171).

---

## Variable Substitution Guide

When using templates, replace these placeholders:

| Placeholder | Example | Description |
|------------|---------|-------------|
| `[FeatureName]` | `BalanceHistory` | PascalCase feature name |
| `[featureName]` | `balanceHistory` | camelCase feature name |
| `[feature-name-kebab]` | `balance-history` | kebab-case for keys |
| `[vietnameseDescription]` | `Lịch sử số dư` | Vietnamese description |
| `[englishDescription]` | `Balance History` | English description |
| `[permissionCode]` | `32119` | 5-digit permission code |
| `[categoryName]` | `leftAccountCategories` | Category array name |
| `[iconName]` | `balance-history-icon` | Icon asset name |
| `[deepLinkPath]` | `balance/history` | Deep link path |
| `[ItemType]` | `BalanceHistoryItem` | Domain model type |
| `[CategoryComment]` | `// Balance` | Category section comment |

---

## Quick Reference: File Update Order

1. ✅ Feature.swift (5 locations) - Template 1-5
2. ✅ FeatureInfo.swift (if has icon) - Template 6
3. ✅ Localizable.strings (vi + en) - Template 7-8
4. ⚠️ ScreenID.swift (if deep linking) - Template 9
5. ⚠️ Route.swift (if deep linking, 4 locations) - Template 10
6. ✅ DeepLinkNavigator.swift (CRITICAL) - Template 15
7. ✅ Feature+Ext.swift (CRITICAL) - Template 16
8. ✅ AppDelegateViewModel.swift (CRITICAL) - Template 17
9. 📝 ViewControllerFactory (manual - show snippet) - Template 11
10. 📝 DependencyContainer (manual - show snippet) - Template 12
11. 📝 Navigator extension (manual - show snippet if deep linking) - Template 13
12. 📝 DeepLinkNavigator route handling (manual - show snippet if deep linking) - Template 14

**Legend:**
- ✅ = Auto-update with Edit tool
- ⚠️ = Auto-update if condition met
- 📝 = Manual implementation (show code snippet only)
