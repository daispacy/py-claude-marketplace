# iOS Feature Generator - Code Templates

Complete code templates for generating iOS Presentation layer features.

---

## Template 1: ViewModel with Date Range Pagination

```swift
// [feature_path]/[Feature]ViewModel.swift

import Foundation
import RxSwift
import RxCocoa
import Domain

// MARK: - Filter Object
struct [Feature]Filter: FilterPaginationDateRangeProvider {
    var toDate: Date = Date()
    var fromDate: Date = Date().addingTimeInterval(-30 * 24 * 60 * 60) // Last 30 days

    // Add custom properties as needed
    // var selectedCategory: Category?
}

// MARK: - ViewModel
final class [Feature]ViewModel: BaseListPaginationDateRangeViewModel<[DomainItemType], [Feature]Filter, Any> {

    // MARK: - Dependencies
    private let [feature]UC: [PrimaryUseCaseType]

    // MARK: - Input
    struct Input {
        let loadTrigger: Observable<Void>
        let loadMoreTrigger: Observable<Void>
        let refreshTrigger: Observable<Void>
        let selectItemTrigger: Observable<IndexPath>
        let changeDateRangeTrigger: Observable<(fromDate: Date, toDate: Date)>
        // Add custom triggers as needed
    }

    // MARK: - Output
    struct Output {
        let items: Driver<[Item]>
        let isLoading: Driver<Bool>
        let shouldLoadMore: Driver<Bool>
        let error: Driver<Error?>
        let selectedItem: Driver<[DomainItemType]>
        // Add custom outputs as needed
    }

    // MARK: - Init
    init(
        [feature]UC: [PrimaryUseCaseType],
        navigator: [Feature]NavigatorType
    ) {
        self.[feature]UC = [feature]UC
        super.init(navigator: navigator, filter: [Feature]Filter())
    }

    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        // Handle date range changes
        input.changeDateRangeTrigger
            .subscribe(onNext: { [weak self] dates in
                var newFilter = self?.filterObject.value ?? [Feature]Filter()
                newFilter.fromDate = dates.fromDate
                newFilter.toDate = dates.toDate
                self?.filterObject.accept(newFilter)
                self?.reload()
            })
            .disposed(by: disposeBag)

        // Base pagination setup
        let baseOutput = super.transform(
            loadTrigger: input.loadTrigger,
            reloadTrigger: input.refreshTrigger,
            loadMoreTrigger: input.loadMoreTrigger
        )

        // Handle item selection
        let selectedItem = input.selectItemTrigger
            .withLatestFrom(baseOutput.items) { indexPath, items in
                items[indexPath.row]
            }
            .asDriverOnErrorJustComplete()

        return Output(
            items: baseOutput.items,
            isLoading: baseOutput.isLoading,
            shouldLoadMore: baseOutput.shouldLoadMore,
            error: baseOutput.error,
            selectedItem: selectedItem
        )
    }

    // MARK: - Fetch Items (Date-based cursor pagination)
    override func fetchItems(_ toDate: Date) -> Observable<[[DomainItemType]]> {
        let filter = filterObject.value

        return [feature]UC.[primaryMethod](
            fromDate: filter.fromDate.toString(format: .defaultFormatDateTime) ?? "",
            toDate: toDate.toString(format: .defaultFormatDateTime) ?? ""
        )
        .asObservable()
        .map { $0.items } // Adjust based on response structure
    }
}
```

---

## Template 2: ViewController with RxSwift Bindings

```swift
// [feature_path]/[Feature]Controller.swift

import UIKit
import RxSwift
import RxCocoa
import Domain

final class [Feature]Controller: BaseViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Properties
    var viewModel: [Feature]ViewModel!

    // MARK: - Triggers
    private let loadTrigger = PublishSubject<Void>()
    private let loadMoreTrigger = PublishSubject<Void>()
    private let refreshTrigger = PublishSubject<Void>()
    private let selectItemTrigger = PublishSubject<IndexPath>()
    private let changeDateRangeTrigger = PublishSubject<(fromDate: Date, toDate: Date)>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()

        // Initial load
        loadTrigger.onNext(())
    }

    // MARK: - Setup
    private func setupUI() {
        title = "[FeatureTitle]"

        // Table view setup
        tableView.do {
            $0.registerCellByNib([MainContentCell].self)
            $0.registerCellByNib(ErrorOrEmptyStateCell.self)
            $0.estimatedRowHeight = 80
            $0.rowHeight = UITableView.automaticDimension
            $0.separatorStyle = .none
        }

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl

        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: refreshTrigger)
            .disposed(by: disposeBag)
    }

    // MARK: - Binding
    private func bindViewModel() {
        let input = [Feature]ViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            loadMoreTrigger: loadMoreTrigger.asObservable(),
            refreshTrigger: refreshTrigger.asObservable(),
            selectItemTrigger: selectItemTrigger.asObservable(),
            changeDateRangeTrigger: changeDateRangeTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        // Bind items to table view
        output.items
            .drive(tableView.rx.items) { [weak self] tableView, index, item in
                guard let self = self else { return UITableViewCell() }

                let cell = tableView.dequeueReusableCell([MainContentCell].self, for: IndexPath(row: index, section: 0))
                cell.configure(with: item)
                return cell
            }
            .disposed(by: disposeBag)

        // Handle loading state
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if !isLoading {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .disposed(by: disposeBag)

        // Handle item selection
        output.selectedItem
            .drive(onNext: { [weak self] item in
                self?.navigator.navigate(to: .[featureName]Detail(item: item))
            })
            .disposed(by: disposeBag)

        // Handle errors
        output.error
            .drive(onNext: { [weak self] error in
                guard let error = error else { return }
                self?.showError(error)
            })
            .disposed(by: disposeBag)

        // Table view selection
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .bind(to: selectItemTrigger)
            .disposed(by: disposeBag)

        // Infinite scroll - trigger load more when near bottom
        tableView.rx.willDisplayCell
            .filter { [weak self] _, indexPath in
                guard let self = self,
                      let itemsCount = try? output.items.asObservable().take(1).toBlocking().first()?.count
                else { return false }
                return indexPath.row >= itemsCount - 3
            }
            .map { _ in () }
            .bind(to: loadMoreTrigger)
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    @IBAction private func didTapDateFilter(_ sender: UIButton) {
        // Navigate to date range picker
        navigator.navigate(to: .dateRangePicker(
            currentFromDate: viewModel.filterObject.value.fromDate,
            currentToDate: viewModel.filterObject.value.toDate,
            onSelect: { [weak self] fromDate, toDate in
                self?.changeDateRangeTrigger.onNext((fromDate: fromDate, toDate: toDate))
            }
        ))
    }
}
```

---

## Template 3: Navigator Extension

```swift
// [feature_path]/Navigator+[Feature].swift

import Foundation
import Domain

// MARK: - Protocol
protocol [Feature]NavigatorType {
    func navigate(to destination: [Feature]Destination)
}

// MARK: - Destinations
enum [Feature]Destination {
    case [featureName]Detail(item: [DomainItemType])
    case dateRangePicker(currentFromDate: Date, currentToDate: Date, onSelect: (Date, Date) -> Void)
    // Add more destinations as needed
}

// MARK: - Navigator Extension
extension Navigator: [Feature]NavigatorType {
    func navigate(to destination: [Feature]Destination) {
        switch destination {
        case .[featureName]Detail(let item):
            let controller = viewControllerFactory.make[Feature]DetailController(item: item)
            push(controller)

        case .dateRangePicker(let fromDate, let toDate, let onSelect):
            let controller = viewControllerFactory.makeDateRangePickerController(
                fromDate: fromDate,
                toDate: toDate,
                onSelect: onSelect
            )
            present(controller, animated: true)
        }
    }
}
```

---

## Template 4: Unit Tests with RxTest

```swift
// PayooMerchantTests/ViewModel/[Feature]ViewModelTests.swift

import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import Domain
@testable import PayooMerchant

final class [Feature]ViewModelTests: XCTestCase {

    private var viewModel: [Feature]ViewModel!
    private var [feature]UC: [PrimaryUseCase]Mock!
    private var navigator: [Feature]NavigatorMock!
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()

        [feature]UC = [PrimaryUseCase]Mock()
        navigator = [Feature]NavigatorMock()
        viewModel = [Feature]ViewModel(
            [feature]UC: [feature]UC,
            navigator: navigator
        )

        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        viewModel = nil
        [feature]UC = nil
        navigator = nil
        scheduler = nil
        disposeBag = nil

        super.tearDown()
    }

    // MARK: - Tests

    func test_Transform_LoadTrigger_ReturnsItems() {
        // Given
        let mockItems = [
            [DomainItemType](id: 1, createdDate: "2025-01-01 10:00:00", title: "Item 1"),
            [DomainItemType](id: 2, createdDate: "2025-01-01 09:00:00", title: "Item 2")
        ]

        [feature]UC.[primaryMethod]ReturnValue = .just([PrimaryResponse](items: mockItems))

        let loadTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])

        // When
        let input = [Feature]ViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            loadMoreTrigger: .never(),
            refreshTrigger: .never(),
            selectItemTrigger: .never(),
            changeDateRangeTrigger: .never()
        )

        let output = viewModel.transform(input)

        let itemsObserver = scheduler.createObserver([[Feature]ViewModel.Item].self)
        output.items
            .drive(itemsObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        // Then
        XCTAssertEqual([feature]UC.[primaryMethod]Called, true)
        XCTAssertEqual(itemsObserver.events.last?.value.element?.count, 2)
    }

    func test_Transform_LoadMoreTrigger_AppendsItems() {
        // Given
        let firstPageItems = [
            [DomainItemType](id: 1, createdDate: "2025-01-01 10:00:00", title: "Item 1")
        ]
        let secondPageItems = [
            [DomainItemType](id: 2, createdDate: "2025-01-01 09:00:00", title: "Item 2")
        ]

        [feature]UC.[primaryMethod]ReturnValue = .just([PrimaryResponse](items: firstPageItems))

        let loadTrigger = scheduler.createHotObservable([.next(10, ())])
        let loadMoreTrigger = scheduler.createHotObservable([.next(20, ())])

        // When
        let input = [Feature]ViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            loadMoreTrigger: loadMoreTrigger.asObservable(),
            refreshTrigger: .never(),
            selectItemTrigger: .never(),
            changeDateRangeTrigger: .never()
        )

        let output = viewModel.transform(input)

        let itemsObserver = scheduler.createObserver([[Feature]ViewModel.Item].self)
        output.items.drive(itemsObserver).disposed(by: disposeBag)

        // Change return value for second page
        scheduler.scheduleAt(15) {
            self.[feature]UC.[primaryMethod]ReturnValue = .just([PrimaryResponse](items: secondPageItems))
        }

        scheduler.start()

        // Then
        XCTAssertEqual(itemsObserver.events.last?.value.element?.count, 2)
    }

    func test_Transform_RefreshTrigger_ReplacesItems() {
        // Test refresh replaces items instead of appending
    }

    func test_Transform_SelectItemTrigger_EmitsSelectedItem() {
        // Test item selection
    }

    func test_Transform_ChangeDateRange_UpdatesFilter() {
        // Test date range filter changes
    }

    func test_Transform_ErrorHandling_EmitsError() {
        // Test error scenarios
    }

    func test_MemoryLeak_WeakSelf_DoesNotRetain() {
        // Given
        weak var weakViewModel = viewModel

        // When
        viewModel = nil

        // Then
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
}

// MARK: - Mocks

final class [PrimaryUseCase]Mock: [PrimaryUseCaseType] {
    var [primaryMethod]Called = false
    var [primaryMethod]ReturnValue: Single<[PrimaryResponse]> = .never()

    func [primaryMethod](fromDate: String, toDate: String) -> Single<[PrimaryResponse]> {
        [primaryMethod]Called = true
        return [primaryMethod]ReturnValue
    }
}

final class [Feature]NavigatorMock: [Feature]NavigatorType {
    var navigateCalled = false
    var navigateDestination: [Feature]Destination?

    func navigate(to destination: [Feature]Destination) {
        navigateCalled = true
        navigateDestination = destination
    }
}
```

---

## Template 5: DependencyContainer Registration

```swift
// Add to DependencyContainer.swift

// MARK: - [Feature] Registration

// Register ViewModel
container.register([Feature]ViewModel.self) { resolver in
    [Feature]ViewModel(
        [feature]UC: resolver.resolve([PrimaryUseCaseType].self)!,
        navigator: resolver.resolve([Feature]NavigatorType.self)!
    )
}
```

---

## Template 6: ViewControllerFactory Extension

```swift
// Add to ViewControllerFactory extension or create new file

extension ViewControllerFactory {
    func make[Feature]Controller() -> [Feature]Controller {
        let controller = [Feature]Controller.instantiate()
        controller.viewModel = DependencyContainer.shared.provide([Feature]ViewModel.self)
        return controller
    }
}
```

---

## Template Variables Reference

When generating code, replace these placeholders:

| Placeholder | Example | Description |
|------------|---------|-------------|
| `[Feature]` | `TransactionHistory` | Feature name in CamelCase |
| `[feature]` | `transactionHistory` | Feature name in camelCase |
| `[featureName]` | `transactionHistory` | Feature name for enum cases |
| `[FeatureTitle]` | `"Transaction History"` | Display title for nav bar |
| `[feature_path]` | `PayooMerchant/Controllers/Transaction/History` | Directory path |
| `[DomainItemType]` | `TransactionItem` | Domain model type |
| `[PrimaryUseCaseType]` | `TransactionHistoryUseCaseType` | UseCase protocol |
| `[PrimaryUseCase]` | `TransactionHistoryUseCase` | UseCase implementation |
| `[primaryMethod]` | `getTransactions` | Main data fetching method |
| `[PrimaryResponse]` | `TransactionHistoryResponse` | Response type |
| `[MainContentCell]` | `TransactionCell` | Main table cell class |

---

## Pagination Type Variations

### Date Range Pagination (Default)
- Extends: `BaseListPaginationDateRangeViewModel`
- Filter: `FilterPaginationDateRangeProvider`
- Item: Must conform to `PaginationDateRangeProvider`

### Page Number Pagination
- Extends: `BaseListPaginationViewModel`
- Override: `fetchItems(_ page: Int)`
- Use: `.page` parameter in API call

### No Pagination
- Extends: `BaseViewModel`
- Single fetch in `transform()`
- No loadMore trigger needed
