# Test Templates

Complete templates for generating iOS RxSwift unit tests.

## ViewModel Test Template

```swift
//
//  {{ClassName}}Tests.swift
//  PayooMerchantTests
//
//  Created by Claude Code on {{Date}}.
//  Copyright © {{Year}} VietUnion. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
import Domain
@testable import PayooMerchant

final class {{ClassName}}Tests: XCTestCase {
    // MARK: - Mocks
    
    {{#each dependencies}}
    private final class Mock{{name}}: {{protocolName}} {
        {{#each methods}}
        var {{name}}Result: {{returnType}} = {{defaultValue}}
        var {{name}}CallCount = 0
        {{#if hasParams}}
        var last{{capitalizedName}}Params: {{paramsType}}?
        {{/if}}
        
        func {{signature}} {
            {{name}}CallCount += 1
            {{#if hasParams}}
            last{{capitalizedName}}Params = {{params}}
            {{/if}}
            return {{name}}Result
        }
        {{/each}}
    }
    {{/each}}
    
    // MARK: - Properties
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!
    {{#each dependencies}}
    private var mock{{name}}: Mock{{name}}!
    {{/each}}
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        {{#each dependencies}}
        mock{{name}} = Mock{{name}}()
        {{/each}}
    }
    
    override func tearDown() {
        disposeBag = nil
        scheduler = nil
        {{#each dependencies}}
        mock{{name}} = nil
        {{/each}}
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    {{#each entities}}
    private func makeTest{{name}}(
        {{#each fields}}
        {{name}}: {{type}} = {{defaultValue}}{{#unless @last}},{{/unless}}
        {{/each}}
    ) -> {{name}} {
        return {{name}}(
            {{#each fields}}
            {{name}}: {{name}}{{#unless @last}},{{/unless}}
            {{/each}}
        )
    }
    {{/each}}
    
    private func makeViewModel() -> {{ClassName}} {
        return {{ClassName}}(
            {{#each dependencies}}
            {{paramName}}: mock{{name}}{{#unless @last}},{{/unless}}
            {{/each}}
        )
    }
    
    // MARK: - Tests
    
    func test_transform_withLoadTrigger_shouldReturnData() {
        // Arrange
        let viewModel = makeViewModel()
        let loadTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])
        
        let input = {{ClassName}}.Input(
            loadTrigger: loadTrigger.asObservable()
        )
        
        mock{{primaryDependency}}.{{primaryMethod}}Result = .just(makeTest{{entity}}())
        
        // Act
        let output = viewModel.transform(input: input)
        let observer = scheduler.createObserver({{outputType}}.self)
        
        output.{{outputProperty}}
            .drive(observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Assert
        XCTAssertEqual(observer.events.count, 1, "Should emit once")
        XCTAssertNotNil(observer.events[0].value.element, "Should have data")
        XCTAssertEqual(mock{{primaryDependency}}.{{primaryMethod}}CallCount, 1, "Should call API once")
    }
    
    func test_transform_withLoadError_shouldDisplayError() {
        // Arrange
        let viewModel = makeViewModel()
        let testError = NSError(domain: "TestError", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "Network error"])
        let loadTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])
        
        let input = {{ClassName}}.Input(
            loadTrigger: loadTrigger.asObservable()
        )
        
        mock{{primaryDependency}}.{{primaryMethod}}Result = .error(testError)
        
        // Act
        let output = viewModel.transform(input: input)
        let observer = scheduler.createObserver(String.self)
        
        output.error
            .drive(observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Assert
        XCTAssertEqual(observer.events.count, 1, "Should emit error")
        let error = observer.events[0].value.element!
        XCTAssertEqual(error, testError.getDescription(), "Should display error message")
    }
    
    func test_transform_withEmptyData_shouldDisplayEmptyMessage() {
        // Arrange
        let viewModel = makeViewModel()
        let loadTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])
        
        let input = {{ClassName}}.Input(
            loadTrigger: loadTrigger.asObservable()
        )
        
        mock{{primaryDependency}}.{{primaryMethod}}Result = .just([])
        
        // Act
        let output = viewModel.transform(input: input)
        let observer = scheduler.createObserver({{outputType}}.self)
        
        output.{{outputProperty}}
            .drive(observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Assert
        let items = observer.events[0].value.element!
        XCTAssertTrue(items.isEmpty, "Should be empty")
    }
    
    func test_transform_withLoadingTriggers_shouldShowLoadingState() {
        // Arrange
        let viewModel = makeViewModel()
        let loadTrigger = scheduler.createHotObservable([
            .next(10, ())
        ])
        
        let input = {{ClassName}}.Input(
            loadTrigger: loadTrigger.asObservable()
        )
        
        mock{{primaryDependency}}.{{primaryMethod}}Result = .just(makeTest{{entity}}())
            .delay(.seconds(1), scheduler: scheduler)
        
        // Act
        let output = viewModel.transform(input: input)
        let loadingObserver = scheduler.createObserver(Bool.self)
        
        output.isLoading
            .drive(loadingObserver)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        // Assert
        XCTAssertTrue(loadingObserver.events.count >= 1, "Should emit loading states")
    }
    
    func test_viewModel_shouldDeallocateProperly() {
        // Arrange
        weak var weakViewModel: {{ClassName}}?
        
        // Act
        autoreleasepool {
            let viewModel = {{ClassName}}(
                {{#each dependencies}}
                {{paramName}}: mock{{name}}{{#unless @last}},{{/unless}}
                {{/each}}
            )
            weakViewModel = viewModel
            
            let input = {{ClassName}}.Input(
                loadTrigger: .never()
            )
            _ = viewModel.transform(input: input)
        }
        
        // Assert
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
}
```

## UseCase Test Template

```swift
//
//  {{ClassName}}Tests.swift
//  PayooMerchantTests
//
//  Created by Claude Code on {{Date}}.
//  Copyright © {{Year}} VietUnion. All rights reserved.
//

import XCTest
import RxSwift
import Domain

class {{ClassName}}Tests: XCTestCase {
    // MARK: - Mocks
    
    {{#each services}}
    private final class Mock{{name}}: {{protocolName}} {
        {{#each methods}}
        var {{name}}ReturnValue: {{returnType}} = {{defaultValue}}
        var {{name}}CallCount = 0
        
        func {{signature}} {
            {{name}}CallCount += 1
            return {{name}}ReturnValue
        }
        {{/each}}
    }
    {{/each}}
    
    // MARK: - Properties
    var useCase: {{ClassName}}!
    {{#each services}}
    var mock{{name}}: Mock{{name}}!
    {{/each}}
    var disposeBag: DisposeBag!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        {{#each services}}
        mock{{name}} = Mock{{name}}()
        {{/each}}
        useCase = {{ClassName}}(
            {{#each services}}
            {{paramName}}: mock{{name}}{{#unless @last}},{{/unless}}
            {{/each}}
        )
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        useCase = nil
        {{#each services}}
        mock{{name}} = nil
        {{/each}}
        disposeBag = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_{{methodName}}_withValidParams_shouldReturnSuccess() {
        // Arrange
        let expectation = self.expectation(description: "Should complete successfully")
        let testData = {{testDataCreation}}
        mock{{service}}.{{method}}ReturnValue = .just(testData)
        
        var result: {{resultType}}?
        var didComplete = false
        
        // Act
        useCase.{{methodName}}({{params}})
            .subscribe(onSuccess: { data in
                result = data
                didComplete = true
                expectation.fulfill()
            }, onError: { _ in
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(didComplete, "Should complete successfully")
        XCTAssertNotNil(result, "Should return data")
        XCTAssertEqual(mock{{service}}.{{method}}CallCount, 1, "Should call service once")
    }
    
    func test_{{methodName}}_withError_shouldReturnError() {
        // Arrange
        let expectation = self.expectation(description: "Should fail with error")
        let testError = NSError(domain: "TestError", code: -1)
        mock{{service}}.{{method}}ReturnValue = .error(testError)
        
        var didError = false
        
        // Act
        useCase.{{methodName}}({{params}})
            .subscribe(onSuccess: { _ in
                expectation.fulfill()
            }, onError: { error in
                didError = true
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(didError, "Should fail with error")
    }
    
    {{#if hasSessionUseCase}}
    func test_catchSessionError_SessionTimeoutError_shouldSetExpiredState() {
        // Arrange
        AppController.shared.state = .loading
        let sessionUC = mock{{sessionUseCase}}!
        let error = SessionTimeoutError()
        let single = Single<{{dataType}}>.error(error)
        let expectation = self.expectation(description: "Should set state expired")
        
        // Act
        let disposable = AppController.shared.rx.state
            .filter { $0 == .expired }
            .take(1)
            .subscribe(onNext: { _ in
                expectation.fulfill()
            })
        
        single.catchSessionError(sessionUC)
            .subscribe()
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        disposable.dispose()
        XCTAssertEqual(AppController.shared.state, .expired)
    }
    
    func test_catchSessionError_ForceUpdateError_shouldSetForceUpdateState() {
        // Arrange
        AppController.shared.state = .loading
        let sessionUC = mock{{sessionUseCase}}!
        let error = ForceUpdateError()
        let completable = Completable.error(error)
        let expectation = self.expectation(description: "Should set force update")
        
        // Act
        let disposable = AppController.shared.rx.state
            .filter { $0 == .forceUpdate }
            .take(1)
            .subscribe(onNext: { _ in
                expectation.fulfill()
            })
        
        completable.catchSessionError(sessionUC)
            .subscribe()
            .disposed(by: disposeBag)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        disposable.dispose()
        XCTAssertEqual(AppController.shared.state, .forceUpdate)
    }
    {{/if}}
}
```

## Mock Template

```swift
private final class Mock{{name}}: {{protocolName}} {
    // Return values
    {{#each methods}}
    var {{name}}Result: {{returnType}} = {{defaultReturnValue}}
    {{/each}}
    
    // Call tracking
    {{#each methods}}
    var {{name}}CallCount = 0
    {{#if hasParams}}
    var last{{capitalizedName}}Params: {{paramsType}}?
    {{/if}}
    {{/each}}
    
    // Protocol implementation
    {{#each methods}}
    func {{signature}} {
        {{name}}CallCount += 1
        {{#if hasParams}}
        last{{capitalizedName}}Params = {{paramsTuple}}
        {{/if}}
        return {{name}}Result
    }
    {{/each}}
}
```

## Test Data Factory Template

```swift
// MARK: - Test Data Factory

private func makeTest{{entityName}}(
    {{#each fields}}
    {{name}}: {{type}} = {{defaultValue}}{{#unless @last}},{{/unless}}
    {{/each}}
) -> {{entityName}} {
    return {{entityName}}(
        {{#each fields}}
        {{name}}: {{name}}{{#unless @last}},{{/unless}}
        {{/each}}
    )
}
```

## Common Default Values

```swift
// RxSwift Observable defaults
.never()        // For not triggering
.just([])       // For empty Observable
.just(value)    // For Single success
.error(error)   // For errors
.empty()        // For Completable

// Common test values
id: 1
name: "Test Name"
amount: 100000.0
date: "2025-12-25 10:30:00"
isEnabled: true
count: 0
```
