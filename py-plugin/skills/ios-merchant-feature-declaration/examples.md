# iOS Feature Declaration - Complete Example

Real-world example of declaring a new "Balance History" feature from start to finish.

---

## Example: Balance History Feature

### User Input (Collected via Form)

```yaml
Feature name: balanceHistory
Vietnamese description: Lịch sử số dư
English description: Balance History
Permission code: 32119
Category: leftAccountCategories
Has icon: yes
Icon name: balance-history-icon
Needs deep linking: no
```

---

## Step-by-Step Updates

### 1. Feature.swift - 5 Locations Updated

**File:** `Domain/Model/Others/Feature.swift`

#### Location 1: Add Feature Case

**Before:**
```swift
// Other
case deposit
case withdrawal
case cardManagement
```

**After:**
```swift
// Other
case deposit
case withdrawal
case balance              // ✅ ADDED
case balanceHistory       // ✅ ADDED (Lịch sử số dư)
case cardManagement
```

---

#### Location 2: Add Permission Code

**Before:**
```swift
case .balance:
    return 32118
case .changePassword:
    return 32115
```

**After:**
```swift
case .balance:
    return 32118
case .balanceHistory:     // ✅ ADDED
    return 32119          // ✅ ADDED
case .changePassword:
    return 32115
```

---

#### Location 3: Add FeatureInfo Mapping

**Before:**
```swift
case .withdrawal:
    return .withdrawal
case .createPaymentRequests:
    return .paymentRequests
```

**After:**
```swift
case .withdrawal:
    return .withdrawal
case .balanceHistory:       // ✅ ADDED
    return .balanceHistory  // ✅ ADDED
case .createPaymentRequests:
    return .paymentRequests
```

---

#### Location 4: Add to Category Array

**Before:**
```swift
public static var leftAccountCategories: [Feature] {
    [.walletInfo, .bankAccount, .palHistory]
}
```

**After:**
```swift
public static var leftAccountCategories: [Feature] {
    [.walletInfo, .bankAccount, .palHistory, .balanceHistory]  // ✅ ADDED
}
```

---

#### Location 5: Add Identifier

**Before:**
```swift
case .balance: "balance"
case .changePassword: "changePassword"
```

**After:**
```swift
case .balance: "balance"
case .balanceHistory: "balanceHistory"  // ✅ ADDED
case .changePassword: "changePassword"
```

---

### 2. FeatureInfo.swift

**File:** `Domain/Model/Others/FeatureInfo.swift`

**Before:**
```swift
static var withdrawal: FeatureInfo {
    FeatureInfo(imageName: "ic_withdrawal", title: "home.label.feature-withdrawal".localized)
}
static var paymentRequests: FeatureInfo {
    FeatureInfo(imageName: "payment_requests", title: "home.label.feature-payment-requests".localized)
}
```

**After:**
```swift
static var withdrawal: FeatureInfo {
    FeatureInfo(imageName: "ic_withdrawal", title: "home.label.feature-withdrawal".localized)
}
static var balanceHistory: FeatureInfo {                                              // ✅ ADDED
    FeatureInfo(                                                                     // ✅ ADDED
        imageName: "balance-history-icon",                                           // ✅ ADDED
        title: "menu.label.balance-history".localized                                // ✅ ADDED
    )                                                                                // ✅ ADDED
}                                                                                    // ✅ ADDED
static var paymentRequests: FeatureInfo {
    FeatureInfo(imageName: "payment_requests", title: "home.label.feature-payment-requests".localized)
}
```

---

### 3. Localization - Vietnamese

**File:** `PayooMerchant/Resources/Localization/vi.lproj/Localizable.strings`

**Append to end of file:**

```strings
/* Balance History */
"menu.label.balance-history" = "Lịch sử số dư";
"home.label.feature-balance-history" = "Lịch sử số dư";
```

---

### 4. Localization - English

**File:** `PayooMerchant/Resources/Localization/en.lproj/Localizable.strings`

**Append to end of file:**

```strings
/* Balance History */
"menu.label.balance-history" = "Balance History";
"home.label.feature-balance-history" = "Balance History";
```

---

## Manual Steps with Code Snippets

### 5. ViewControllerFactory Method

**File:** `PayooMerchant/Library/Core/ViewControllerFactory.swift`

**Add this extension:**

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

### 6. DependencyContainer Registration

**File:** `PayooMerchant/Library/Core/DependencyContainer.swift`

**Add to ViewModel registration section:**

```swift
// Register Balance History ViewModel
container.register(BalanceHistoryViewModel.self) { resolver in
    BalanceHistoryViewModel(
        balanceHistoryUC: resolver.resolve(BalanceHistoryUseCaseType.self)!,
        navigator: resolver.resolve(BalanceHistoryNavigatorType.self)!
    )
}
```

---

### 7. Create ViewController and ViewModel

**Create these files:**

- `PayooMerchant/Controllers/Balance/History/BalanceHistoryController.swift`
- `PayooMerchant/Controllers/Balance/History/BalanceHistoryController.xib`
- `PayooMerchant/Controllers/Balance/History/BalanceHistoryViewModel.swift`

**ViewModel structure:**
```swift
import Foundation
import RxSwift
import RxCocoa
import Domain

final class BalanceHistoryViewModel: BaseListPaginationDateRangeViewModel<BalanceHistoryItem, BalanceHistoryFilter, Any> {

    // MARK: - Dependencies
    private let balanceHistoryUC: BalanceHistoryUseCaseType

    // MARK: - Input
    struct Input {
        let loadTrigger: Observable<Void>
        let loadMoreTrigger: Observable<Void>
        let refreshTrigger: Observable<Void>
        let selectItemTrigger: Observable<IndexPath>
    }

    // MARK: - Output
    struct Output {
        let items: Driver<[Item]>
        let isLoading: Driver<Bool>
        let shouldLoadMore: Driver<Bool>
        let error: Driver<Error?>
        let selectedItem: Driver<BalanceHistoryItem>
    }

    // MARK: - Init
    init(
        balanceHistoryUC: BalanceHistoryUseCaseType,
        navigator: BalanceHistoryNavigatorType
    ) {
        self.balanceHistoryUC = balanceHistoryUC
        super.init(navigator: navigator, filter: BalanceHistoryFilter())
    }

    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        // Implementation
    }
}
```

---

### 8. Add Icon Assets

**Location:** `PayooMerchant/Resources/Assets.xcassets/`

**Create:**
- `balance-history-icon.imageset/`
  - `balance-history-icon.png` (24x24 pt)
  - `balance-history-icon@2x.png` (48x48 pt)
  - `balance-history-icon@3x.png` (72x72 pt)

**Contents.json:**
```json
{
  "images" : [
    {
      "filename" : "balance-history-icon.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "balance-history-icon@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "balance-history-icon@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

## Final Output Summary

```markdown
✅ Feature Declared: BalanceHistory

📋 Collected Details:
  - Name: balanceHistory
  - Vietnamese: Lịch sử số dư
  - English: Balance History
  - Permission Code: 32119
  - Category: leftAccountCategories
  - Icon: balance-history-icon
  - Deep Link: None

📁 Files Updated:
  ✅ Domain/Model/Others/Feature.swift (5 locations)
  ✅ Domain/Model/Others/FeatureInfo.swift
  ✅ PayooMerchant/Resources/Localization/vi.lproj/Localizable.strings
  ✅ PayooMerchant/Resources/Localization/en.lproj/Localizable.strings

📝 Manual Steps Required:

1. Add Icon Assets:
   - Location: PayooMerchant/Resources/Assets.xcassets/
   - Create: balance-history-icon.imageset/
   - Add images: 1x (24x24), 2x (48x48), 3x (72x72 pt)

2. Add ViewControllerFactory Method:
   extension ViewControllerFactory {
       func makeBalanceHistoryController() -> BalanceHistoryController {
           let controller = BalanceHistoryController.instantiate()
           controller.viewModel = DependencyContainer.shared.provide(BalanceHistoryViewModel.self)
           return controller
       }
   }

3. Register in DependencyContainer:
   container.register(BalanceHistoryViewModel.self) { resolver in
       BalanceHistoryViewModel(
           balanceHistoryUC: resolver.resolve(BalanceHistoryUseCaseType.self)!,
           navigator: resolver.resolve(BalanceHistoryNavigatorType.self)!
       )
   }

4. Create ViewController and ViewModel:
   - BalanceHistoryController.swift
   - BalanceHistoryViewModel.swift
   - Follow MVVM + RxSwift Input/Output pattern

✅ Verification Checklist:
  - [ ] Build project successfully
  - [ ] Run SwiftLint (bundle exec fastlane lint)
  - [ ] Test without permission 32119 (should hide feature)
  - [ ] Test with permission 32119 (should show in Account section)
  - [ ] Verify Vietnamese text: "Lịch sử số dư"
  - [ ] Verify English text: "Balance History"
  - [ ] Test icon displays correctly
  - [ ] Test navigation to feature

🔗 Next Steps:
  1. Add icon assets to Assets.xcassets
  2. Implement BalanceHistoryController and BalanceHistoryViewModel
  3. Add factory method to ViewControllerFactory
  4. Register ViewModel in DependencyContainer
  5. Test thoroughly before committing

📚 Reference: NEW_FEATURE_DECLARATION_PLAN.md
```

---

## Example 2: With Deep Linking

### User Input

```yaml
Feature name: orderTracking
Vietnamese description: Theo dõi đơn hàng
English description: Order Tracking
Permission code: 34500
Category: leftOnlineCategories
Has icon: yes
Icon name: order-tracking-icon
Needs deep linking: yes
Deep link path: order/tracking
```

### Additional Files Updated (Deep Linking)

#### ScreenID.swift

**File:** `Domain/Model/Setting/ScreenID.swift`

```swift
// Order Tracking
case orderTracking = "order/tracking"
case orderTrackingDetail = "order/tracking/detail"
```

#### Route.swift

**File:** `PayooMerchant/Library/DeepLink/Route.swift`

**Add enum case:**
```swift
enum Route {
    case orderTracking
    case orderTrackingDetail(order: Order)
}
```

**Add URL mapping:**
```swift
init?(url: URL) {
    switch url {
    case ScreenID.orderTracking.url:
        self = .orderTracking

    default:
        if url.absoluteString.contains(ScreenID.orderTrackingDetail.url.absoluteString),
           let params = url.queryParameters,
           let orderId = params["id"] {
            // Create order from orderId
            self = .orderTrackingDetail(order: order)
        }
    }
}
```

#### Navigator Extension (Manual)

**File:** `PayooMerchant/Controllers/Order/Tracking/Navigator+OrderTracking.swift`

```swift
import Foundation
import Domain

protocol OrderTrackingNavigatorType {
    func navigate(to destination: OrderTrackingDestination)
}

enum OrderTrackingDestination {
    case orderTrackingDetail(order: Order)
}

extension Navigator: OrderTrackingNavigatorType {
    func navigate(to destination: OrderTrackingDestination) {
        switch destination {
        case .orderTrackingDetail(let order):
            let controller = viewControllerFactory.makeOrderTrackingDetailController(order: order)
            push(controller)
        }
    }
}
```

#### DeepLinkNavigator (Manual)

**File:** `PayooMerchant/Library/DeepLink/DeepLinkNavigator.swift`

**Add to navigate method:**
```swift
case .orderTracking:
    let controller = viewControllerFactory.makeOrderTrackingController()
    navigator.push(controller)

case .orderTrackingDetail(let order):
    let controller = viewControllerFactory.makeOrderTrackingDetailController(order: order)
    navigator.push(controller)
```

---

## Testing the Feature

### 1. Permission Testing

**Without Permission (code 32119 not in user permissions):**
```
Result: Feature should NOT appear in Account section menu
```

**With Permission (code 32119 in user permissions):**
```
Result: Feature SHOULD appear in Account section menu with:
- Icon: balance-history-icon
- Title (VI): "Lịch sử số dư"
- Title (EN): "Balance History"
```

### 2. Localization Testing

**Switch to Vietnamese:**
```
Menu text: "Lịch sử số dư"
```

**Switch to English:**
```
Menu text: "Balance History"
```

### 3. Deep Link Testing (if applicable)

**Test URL:**
```
payoo://order/tracking
```

**Result:**
```
Should navigate to OrderTrackingController
```

**Test URL with parameter:**
```
payoo://order/tracking/detail?id=12345
```

**Result:**
```
Should navigate to OrderTrackingDetailController with order ID 12345
```

---

## Common Patterns

### Pattern 1: Feature Without Permission

```yaml
Feature name: settings
Permission code: (empty)
```

**Result:** Feature appears for all users, no permission check.

### Pattern 2: Feature Without Icon

```yaml
Has icon: no
```

**Result:** FeatureInfo.swift NOT updated, feature doesn't appear in visual menus.

### Pattern 3: Parent-Child Features

**Parent:**
```yaml
Feature name: installmentFeeCheck
Permission code: 33200
```

**Child 1:**
```yaml
Feature name: installmentFeeCheckOnline
Permission code: 33101
```

**Child 2:**
```yaml
Feature name: installmentFeeCheckInStore
Permission code: 33201
```

**Result:** Parent feature combines child permissions.

---

## Verification Steps

After declaring a feature, verify:

1. **Build Success:**
   ```bash
   xcodebuild -workspace PayooMerchant.xcworkspace \
     -scheme "Payoo Merchant Sandbox" \
     -configuration "Debug Sandbox" \
     -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15,arch=x86_64' \
     clean build
   ```

2. **SwiftLint Pass:**
   ```bash
   bundle exec fastlane lint
   ```

3. **Feature Appears in Menu:**
   - Login with user that has the permission code
   - Navigate to the appropriate menu category
   - Verify feature appears with correct icon and text

4. **Localization Works:**
   - Test in both Vietnamese and English
   - Verify all text is properly localized

5. **Deep Link Works (if applicable):**
   - Test deep link URL in Safari or via push notification
   - Verify navigation to correct screen

---

This example demonstrates the complete end-to-end process of declaring a new feature!
