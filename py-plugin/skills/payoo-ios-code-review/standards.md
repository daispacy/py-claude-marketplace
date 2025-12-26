# Payoo iOS Coding Standards

Detailed coding standards and rules for the Payoo Merchant iOS app.

## Architecture Standards

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│   Presentation (PayooMerchant)     │  ← ViewControllers, ViewModels, UI
├─────────────────────────────────────┤
│   Domain                            │  ← UseCases, Entities, Protocols
├─────────────────────────────────────┤
│   Data                              │  ← API, Realm, Services Implementation
├─────────────────────────────────────┤
│   Analytics                         │  ← Firebase tracking
└─────────────────────────────────────┘
```

**Import Rules:**
- ✓ Presentation can import: Domain, Analytics
- ✓ Data can import: Domain
- ✓ Domain imports: Nothing (pure Swift + RxSwift)
- ✗ NEVER: Domain imports Data/Presentation
- ✗ NEVER: Data imports Presentation

### MVVM Pattern

**ViewModelType Protocol:**
```swift
protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}
```

**ViewModel Structure:**
```swift
final class FeatureViewModel: ViewModelType {
    // MARK: - Dependencies (injected)
    private let useCase: UseCaseType
    private let navigator: NavigatorType
    private let sessionUC: SessionUseCaseType

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // MARK: - Init
    init(useCase: UseCaseType, navigator: NavigatorType, sessionUC: SessionUseCaseType) {
        self.useCase = useCase
        self.navigator = navigator
        self.sessionUC = sessionUC
    }

    // MARK: - Input/Output
    struct Input {
        let trigger: Driver<Void>
    }

    struct Output {
        let result: Driver<DataType>
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        // Implementation
    }
}
```

**ViewController Structure:**
```swift
final class FeatureViewController: BaseViewController {
    // MARK: - Dependencies (injected)
    private let viewModel: FeatureViewModelType
    private let navigator: NavigatorType

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Init
    init(viewModel: FeatureViewModelType, navigator: NavigatorType) {
        self.viewModel = viewModel
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        // UI setup
    }

    // MARK: - Binding
    private func bindViewModel() {
        let input = FeatureViewModel.Input(
            trigger: rx.viewWillAppear.asDriver()
        )
        let output = viewModel.transform(input: input)

        output.result
            .drive(tableView.rx.items(cellIdentifier: "Cell")) { _, item, cell in
                // Configure cell
            }
            .disposed(by: disposeBag)
    }
}
```

## RxSwift Standards

### Observable Types

**Driver** - UI bindings (main thread, never errors):
```swift
let username: Driver<String> = usernameTextField.rx.text
    .orEmpty
    .asDriver(onErrorJustReturn: "")
```

**Single** - One-time operations:
```swift
func login(username: String, password: String) -> Single<User> {
    return apiService.login(username: username, password: password)
        .catchSessionError(sessionUC)
}
```

**Observable** - Streams:
```swift
let searchResults: Observable<[Result]> = searchTextField.rx.text
    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    .flatMapLatest { query in
        return self.searchUC.search(query: query)
    }
```

**Maybe** - Optional single value:
```swift
func getProfile() -> Maybe<Profile> {
    return apiService.getProfile()
        .catchSessionError(sessionUC)
}
```

### Memory Management

**Always use [weak self]:**
```swift
// ✓ CORRECT
observable
    .subscribe(onNext: { [weak self] value in
        self?.updateUI(value)
    })
    .disposed(by: disposeBag)

// ✗ WRONG - Retain cycle!
observable
    .subscribe(onNext: { value in
        self.updateUI(value)
    })
    .disposed(by: disposeBag)
```

**flatMapLatest with weak self:**
```swift
// ✓ CORRECT
input.trigger
    .flatMapLatest { [weak self] _ -> Observable<Data> in
        guard let self = self else { return .empty() }
        return self.useCase.execute()
    }

// ✗ WRONG - Memory leak!
input.trigger
    .flatMapLatest { _ in
        return self.useCase.execute()
    }
```

**DisposeBag required:**
```swift
// ✓ CORRECT
private let disposeBag = DisposeBag()

observable.subscribe(onNext: { _ in })
    .disposed(by: disposeBag)

// ✗ WRONG - Subscription never disposed!
observable.subscribe(onNext: { _ in })
```

### Session Error Handling

**CRITICAL RULE**: All API calls MUST use `.catchSessionError(sessionUC)`

```swift
// ✓ CORRECT
func getData() -> Observable<Data> {
    return apiService.getData()
        .catchSessionError(sessionUC)
}

// ✗ WRONG - Session errors not handled!
func getData() -> Observable<Data> {
    return apiService.getData()
}
```

**Why this matters:**
- Session timeout → Auto logout
- Invalid token → Force re-login
- Force update → Block app usage

## Dependency Injection (Swinject)

### Registration in DependencyContainer

```swift
// Register UseCase
container.register(FeatureUseCaseType.self) { resolver in
    let apiService = resolver.resolve(ApiService.self)!
    let sessionUC = resolver.resolve(SessionUseCaseType.self)!
    return FeatureUseCase(apiService: apiService, sessionUC: sessionUC)
}

// Register ViewModel
container.register(FeatureViewModelType.self) { resolver in
    let useCase = resolver.resolve(FeatureUseCaseType.self)!
    let navigator = resolver.resolve(NavigatorType.self)!
    let sessionUC = resolver.resolve(SessionUseCaseType.self)!
    return FeatureViewModel(useCase: useCase, navigator: navigator, sessionUC: sessionUC)
}
```

### Usage

```swift
// ✓ CORRECT - Use DependencyContainer
let viewModel = DependencyContainer.shared.provide(FeatureViewModelType.self)

// ✗ WRONG - Direct instantiation
let viewModel = FeatureViewModel(useCase: useCase, navigator: navigator, sessionUC: sessionUC)
```

### ViewControllerFactory

```swift
// ✓ CORRECT - Use factory
protocol ViewControllerFactory {
    func makeFeatureViewController() -> FeatureViewController
}

extension DependencyContainer: ViewControllerFactory {
    func makeFeatureViewController() -> FeatureViewController {
        let viewModel = provide(FeatureViewModelType.self)
        let navigator = provide(FeatureNavigatorType.self)
        return FeatureViewController(viewModel: viewModel, navigator: navigator)
    }
}

// Usage
let vc = DependencyContainer.shared.makeFeatureViewController()

// ✗ WRONG - Direct instantiation
let vc = FeatureViewController(viewModel: viewModel, navigator: navigator)
```

## Navigation Standards

### Navigator Pattern

```swift
enum FeatureDestination {
    case detail(id: String)
    case settings
    case back
}

protocol FeatureNavigatorType {
    func navigate(to destination: FeatureDestination)
}

final class FeatureNavigator: FeatureNavigatorType {
    private weak var navigationController: UINavigationController?
    private let factory: ViewControllerFactory

    init(navigationController: UINavigationController?, factory: ViewControllerFactory) {
        self.navigationController = navigationController
        self.factory = factory
    }

    func navigate(to destination: FeatureDestination) {
        switch destination {
        case .detail(let id):
            let vc = factory.makeDetailViewController(id: id)
            navigationController?.pushViewController(vc, animated: true)
        case .settings:
            let vc = factory.makeSettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .back:
            navigationController?.popViewController(animated: true)
        }
    }
}
```

### Usage in ViewModel

```swift
func transform(input: Input) -> Output {
    input.detailTrigger
        .drive(onNext: { [weak self] id in
            self?.navigator.navigate(to: .detail(id: id))
        })
        .disposed(by: disposeBag)

    return Output()
}
```

## UseCase Standards

### Protocol Definition

```swift
public protocol FeatureUseCaseType {
    func execute(param: String) -> Single<Result>
    func refresh() -> Observable<[Item]>
}
```

### Implementation

```swift
public final class FeatureUseCase: FeatureUseCaseType {
    private let apiService: ApiService
    private let sessionUC: SessionUseCaseType

    public init(apiService: ApiService, sessionUC: SessionUseCaseType) {
        self.apiService = apiService
        self.sessionUC = sessionUC
    }

    public func execute(param: String) -> Single<Result> {
        return apiService.getData(param: param)
            .catchSessionError(sessionUC)
    }

    public func refresh() -> Observable<[Item]> {
        return apiService.getItems()
            .catchSessionError(sessionUC)
    }
}
```

### UseCase Composition

ViewModels compose multiple UseCases:

```swift
final class FeatureViewModel: ViewModelType {
    private let profileUC: ProfileUseCaseType
    private let itemsUC: ItemsUseCaseType
    private let analyticsUC: AnalyticsUseCaseType

    func transform(input: Input) -> Output {
        let data = Observable.combineLatest(
            profileUC.getProfile(),
            itemsUC.getItems()
        ).map { profile, items in
            return (profile, items)
        }

        return Output(data: data.asDriver(onErrorJustReturn: (nil, [])))
    }
}
```

## SwiftLint Rules

### Enabled Opt-in Rules

- `empty_count` - Use `.isEmpty` instead of `.count == 0`
- `closure_spacing` - Proper spacing in closures
- `closure_end_indentation` - Align closing braces
- `yoda_condition` - Constant on right side: `x == 5` not `5 == x`
- `implicit_return` - Can omit return in single-expression closures
- `modifier_order` - Consistent modifier order
- `todo` - Track TODO/FIXME comments

### Limits

- **Type body length**: 300 (warning), 400 (error)
- **File length**: 800 (warning), 1200 (error)
- **Type name**: 60 (warning), 80 (error)
- **Line length**: Disabled (flexible)

### Common Violations

```swift
// ✗ WRONG - empty_count
if array.count == 0 { }

// ✓ CORRECT
if array.isEmpty { }

// ✗ WRONG - yoda_condition
if 5 == x { }

// ✓ CORRECT
if x == 5 { }

// ✗ WRONG - todo without tracking
// TODO: fix this

// ✓ CORRECT
// TODO: [PAYOO-123] Fix authentication timeout

// ✗ WRONG - explicit_init
let view = UIView.init()

// ✓ CORRECT
let view = UIView()
```

## Naming Conventions

### Classes

```swift
// ViewModels
LoginViewModel
TransactionHistoryViewModel
SettingsViewModel

// ViewControllers
LoginViewController
TransactionHistoryViewController
SettingsViewController

// UseCases
LoginUseCase
GetProfileUseCase
UpdateSettingsUseCase

// Services (Protocols)
ApiService
LocalStorageService
AnalyticsService

// Services (Implementations)
DefaultApiService
RealmStorageService
FirebaseAnalyticsService
```

### Protocols

```swift
// Type suffix for main protocols
ViewModelType
UseCaseType
NavigatorType

// Specific protocols
FeatureViewModelType
FeatureUseCaseType
FeatureNavigatorType
```

### Variables

```swift
// Use descriptive names
let transactionItems: [TransactionItem]
let isLoading: Bool
let errorMessage: String

// Avoid abbreviations
let usrNm: String  // ✗ WRONG
let username: String  // ✓ CORRECT

// RxSwift subjects
private let loadTrigger = PublishSubject<Void>()
private let selectedItem = BehaviorSubject<Item?>(value: nil)
```

### Constants

```swift
// Global constants
let kMaxRetryCount = 3
let kDefaultTimeout: TimeInterval = 30

// Local constants
private let pageSize = 20
private let animationDuration: TimeInterval = 0.3
```

## Common Patterns

### Data Collector Pattern

For multi-step flows:

```swift
struct WithdrawalDataCollector {
    var bankAccount: BankAccount?
    var amount: String?
    var otp: String?
}

// Pass through navigation
navigator.navigate(to: .enterAmount(collector: collector))
```

### Loading State Pattern

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}

// In ViewModel
let state: Driver<LoadingState<Data>>
```

### Error Handling Pattern

```swift
// In ViewModel
input.trigger
    .flatMapLatest { [weak self] _ -> Driver<Result> in
        guard let self = self else { return .empty() }
        return self.useCase.execute()
            .catchSessionError(self.sessionUC)
            .asDriver(onErrorJustReturn: .failure(.unknown))
    }
```

## Testing Standards

### UseCase Tests

```swift
final class FeatureUseCaseTests: XCTestCase {
    var sut: FeatureUseCase!
    var mockApiService: MockApiService!
    var mockSessionUC: MockSessionUseCase!

    override func setUp() {
        super.setUp()
        mockApiService = MockApiService()
        mockSessionUC = MockSessionUseCase()
        sut = FeatureUseCase(apiService: mockApiService, sessionUC: mockSessionUC)
    }

    func testExecute_Success() {
        // Given
        let expectedResult = Result.success
        mockApiService.stub = .just(expectedResult)

        // When
        let result = sut.execute(param: "test").toBlocking().materialize()

        // Then
        XCTAssertEqual(result, .completed(expectedResult))
    }
}
```

### ViewModel Tests

```swift
final class FeatureViewModelTests: XCTestCase {
    var sut: FeatureViewModel!
    var mockUseCase: MockFeatureUseCase!
    var mockNavigator: MockNavigator!

    func testTransform_LoadsData() {
        // Given
        let expectedData = [Item()]
        mockUseCase.stub = .just(expectedData)

        let input = FeatureViewModel.Input(
            trigger: .just(())
        )

        // When
        let output = sut.transform(input: input)

        // Then
        let result = output.data.toBlocking().first()
        XCTAssertEqual(result, expectedData)
    }
}
```

## Security Standards

### Sensitive Data

```swift
// ✗ WRONG - Logging sensitive data
print("Password: \(password)")

// ✓ CORRECT
print("Login attempt")

// ✗ WRONG - Storing passwords
UserDefaults.standard.set(password, forKey: "password")

// ✓ CORRECT - Use Keychain
KeychainService.save(password, forKey: "password")
```

### API Keys

```swift
// ✗ WRONG - Hardcoded keys
let apiKey = "abc123xyz"

// ✓ CORRECT - Use build configuration
let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String
```

## Performance Standards

### Avoid Unnecessary Computations

```swift
// ✗ WRONG - Computing in every cell
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = items[indexPath.row]
    let formattedDate = DateFormatter().string(from: item.date)  // Creates formatter every time!
    cell.dateLabel.text = formattedDate
    return cell
}

// ✓ CORRECT - Reuse formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = items[indexPath.row]
    cell.dateLabel.text = dateFormatter.string(from: item.date)
    return cell
}
```

### Image Loading

```swift
// ✓ CORRECT - Use Kingfisher
imageView.kf.setImage(with: URL(string: imageUrl))

// Configure caching
KingfisherManager.shared.cache.maxDiskCacheSize = 100 * 1024 * 1024  // 100MB
```

### Debouncing

```swift
// Search with debounce
searchTextField.rx.text
    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    .distinctUntilChanged()
    .flatMapLatest { query in
        return self.searchUC.search(query: query)
    }
```

## Documentation Standards

### Header Comments

```swift
//
//  FeatureViewModel.swift
//  PayooMerchant
//
//  Created by Developer Name on 2024-01-01.
//  Copyright © 2024 VietUnion. All rights reserved.
//
```

### MARK Comments

```swift
// MARK: - Properties
// MARK: - Init
// MARK: - Lifecycle
// MARK: - Setup
// MARK: - Binding
// MARK: - Actions
// MARK: - Private Methods
```

### TODO/FIXME

```swift
// TODO: [PAYOO-123] Implement pagination
// FIXME: [PAYOO-456] Fix memory leak in subscription
// NOTE: This is a temporary workaround for iOS 12 compatibility
```
