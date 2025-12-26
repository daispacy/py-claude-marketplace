# Workflow Examples

## Example 1: Review Mode - Existing MR

**Scenario**: User wants to review an existing merge request for a SmartOTP feature.

**Input:**
```
mode: review
project: rnd/ios/payoo-ios-app-merchant
branch: feature/smart-otp
issue_number: 1214
target_branch: develop
```

**Workflow:**

**Step 1**: Gather information ✅

**Step 2**: Fetch MR and validate mode
```bash
# MCP call
mobile-mcp-server/gitlab-get-merge-request
  projectName: rnd/ios/payoo-ios-app-merchant
  branch: feature/smart-otp

# Result: MR !543 found
# Mode: review (continue in review mode)
```

**Step 3**: Analyze code changes
```bash
# Get MR changes
mobile-mcp-server/gitlab-get-merge-request-changes
  mrIid: 543
  projectName: rnd/ios/payoo-ios-app-merchant

# Git operations
git status --porcelain  # Check for changes
git stash               # Stash if needed
git checkout feature/smart-otp
git stash pop           # Restore if needed

# Read all changed files
Read: PayooMerchant/Controllers/SmartOTP/SmartOTPViewController.swift
Read: PayooMerchant/ViewModels/SmartOTP/SmartOTPViewModel.swift
Read: Domain/UseCase/SmartOTP/GetSmartOTPCodeUseCase.swift
Read: PayooMerchantTests/ViewModels/SmartOTPViewModelTests.swift
```

**Step 4**: Execute review mode actions

**4a. Generate review report:**
```markdown
# 📝 Code Review Analysis

## Summary
SmartOTP feature implementation with ViewModel, ViewController, and UseCase.
Overall good Clean Architecture separation. Few issues to address.

## Critical Issues ⛔
None

## Major Issues ⚠️
1. Missing `.catchSessionError()` on API call
   - Location: GetSmartOTPCodeUseCase.swift:45
   - Impact: Session timeout won't trigger auto-logout
   - Fix: Add `.catchSessionError(sessionUC)` after API call

2. Potential retain cycle in closure
   - Location: SmartOTPViewModel.swift:78
   - Impact: Memory leak
   - Fix: Use `[weak self]` in RxSwift binding

## Minor Issues 💡
1. Magic number for timeout
   - Location: SmartOTPViewController.swift:120
   - Suggestion: Extract to constant

## Positive Observations ✅
- Clean Architecture layers properly separated
- Good test coverage (12 test cases)
- MVVM pattern correctly implemented
- Dispose bags properly used

## Recommendations 📚
- Consider adding integration tests
- Document the OTP verification flow

## Security Review 🔒
- OTP code handling looks secure
- No sensitive data logged

## Testing Assessment 🧪
- Good unit test coverage
- Edge cases covered
- Mock objects properly implemented

## Performance Analysis ⚡
- No performance concerns identified
- Async operations properly handled

# 🔍 Review Decision

**Status**: Changes Requested ⚠️

**Next Steps:**
1. Fix major issue #1: Add session error handling
2. Fix major issue #2: Fix potential retain cycle
3. Optional: Address minor issue
```

**4b. Post review comments:**
```bash
mobile-mcp-server/gitlab-review-merge-request-code
  # Posts inline comments for each major and minor issue
```

**4c. Approval decision:**
- Issues found → Withhold approval
- Post detailed feedback

**4d. Summary:**
```
✅ Code Review Complete
MR: #543
Critical Issues: 0
Major Issues: 2
Minor Issues: 1
Status: Changes Requested ⚠️
```

## Example 2: Review Mode - MR Doesn't Exist (Auto-switch to Update)

**Scenario**: User tries to review but MR doesn't exist yet.

**Input:**
```
mode: review
project: rnd/ios/payoo-ios-app-merchant
branch: bugfix/payment-crash
issue_number: 1250
target_branch: develop
```

**Workflow:**

**Step 2**: Fetch MR
```bash
mobile-mcp-server/gitlab-get-merge-request
  projectName: rnd/ios/payoo-ios-app-merchant
  branch: bugfix/payment-crash

# Result: MR not found
# Action: Force switch to "update" mode
```

**User notification:**
```
⚠️ Merge request not found for branch 'bugfix/payment-crash'
Automatically switching to UPDATE mode to create the MR.
```

**Continue with Update Mode workflow** (see Example 3)

## Example 3: Update Mode - Create New MR

**Scenario**: User wants to create a new merge request.

**Input:**
```
mode: update
project: rnd/ios/payoo-ios-app-merchant
branch: feature/qr-scanner
issue_number: 1275
target_branch: develop
```

**Workflow:**

**Step 2**: Fetch MR
```bash
mobile-mcp-server/gitlab-get-merge-request
  projectName: rnd/ios/payoo-ios-app-merchant
  branch: feature/qr-scanner

# Result: MR not found
# Mode: update (continue in update mode)
```

**Step 3**: Analyze code changes
```bash
# Read changed files to understand implementation
Read: PayooMerchant/Controllers/QRScanner/QRScannerViewController.swift
Read: Domain/UseCase/QRScanner/ScanQRCodeUseCase.swift
# ... etc
```

**Step 4**: Update mode actions

**4a. Generate MR description:**
```markdown
# 📲 What

Close #1275

Implement QR code scanner feature for payment processing. Users can now scan
merchant QR codes to initiate payments quickly without manual entry.

# 🛠 How

- Created QRScannerViewController with AVFoundation camera integration
- Implemented ScanQRCodeUseCase for QR code validation
- Added QRScannerViewModel with RxSwift bindings
- Integrated with existing payment flow
- Added permission handling for camera access

Key decisions:
- Used AVFoundation for native camera access
- Implemented debouncing to prevent multiple scans
- Added error handling for invalid QR formats

# 📚 How to Use

\`\`\`swift
// Navigate to QR scanner
let viewModel = QRScannerViewModel(scanUseCase: scanUseCase)
let scanner = QRScannerViewController(viewModel: viewModel)
navigationController?.push(scanner)

// Handle scan result
viewModel.output.scannedCode
    .subscribe(onNext: { qrCode in
        // Process QR code
    })
    .disposed(by: disposeBag)
\`\`\`

/assign me
/label ~"product::payoomerchant" ~"team::ios" ~"In Review"
```

**4b. Create MR:**
```bash
mobile-mcp-server/gitlab-create-merge-request
  projectName: rnd/ios/payoo-ios-app-merchant
  sourceBranch: feature/qr-scanner
  targetBranch: develop
  title: "Implement QR code scanner for payment processing"
  description: [generated description above]

# Result: MR !555 created
```

**4c. Summary:**
```
✅ MR Created
MR: #555
URL: https://gitlab.com/rnd/ios/payoo-ios-app-merchant/-/merge_requests/555
Title: Implement QR code scanner for payment processing
Status: Ready for review
```

## Example 4: Update Mode - Update Existing MR

**Scenario**: User wants to update description of existing MR.

**Input:**
```
mode: update
project: rnd/ios/payoo-ios-app-merchant
branch: feature/biometric-auth
issue_number: 1280
target_branch: develop
```

**Workflow:**

**Step 2**: Fetch MR
```bash
mobile-mcp-server/gitlab-get-merge-request
  projectName: rnd/ios/payoo-ios-app-merchant
  branch: feature/biometric-auth

# Result: MR !560 found
# Mode: update (continue in update mode)
```

**Step 3**: Analyze code changes (same as Example 3)

**Step 4**: Update mode actions

**4a. Generate new description** (same format as Example 3)

**4b. Update MR:**
```bash
mobile-mcp-server/gitlab-update-merge-request-description
  project: rnd/ios/payoo-ios-app-merchant
  mrIid: 560
  newDescription: [generated description]

# Result: MR !560 description updated
```

**4c. Summary:**
```
✅ MR Updated
MR: #560
URL: https://gitlab.com/rnd/ios/payoo-ios-app-merchant/-/merge_requests/560
Status: Description updated, ready for review
```

## Example 5: Review Mode - Approve MR

**Scenario**: Review finds no blocking issues, MR can be approved.

**Input:**
```
mode: review
project: rnd/ios/payoo-ios-app-merchant
branch: bugfix/login-validation
issue_number: 1290
target_branch: develop
```

**Workflow:**

**Steps 1-3**: Same as Example 1

**Step 4**: Review mode actions

**4a. Review report:**
```markdown
# 📝 Code Review Analysis

## Summary
Bug fix for login validation. Clean implementation, all best practices followed.

## Critical Issues ⛔
None

## Major Issues ⚠️
None

## Minor Issues 💡
1. Could add test for edge case with empty password

## Positive Observations ✅
- Proper input validation
- Good error messages
- Session error handling present
- Memory management correct
- Test coverage adequate

# 🔍 Review Decision

**Status**: Approved ✅

**Approval Criteria Met:**
- [x] No critical issues
- [x] Major issues addressed or acceptable
- [x] Code follows iOS best practices
- [x] Adequate test coverage
- [x] No security vulnerabilities

**Next Steps:**
- Can merge when ready
- Consider adding edge case test in future
```

**4c. Approve MR:**
```bash
mobile-mcp-server/gitlab-approve-merge-request
  project: rnd/ios/payoo-ios-app-merchant
  mrIid: 565

# Result: MR !565 approved
```

**Summary:**
```
✅ Code Review Complete
MR: #565
Critical Issues: 0
Major Issues: 0
Minor Issues: 1
Status: Approved ✅

MR is ready to merge!
```
