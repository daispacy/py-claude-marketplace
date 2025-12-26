# Workflow Examples

## Example 1: Bugfix Mode

**Scenario**: User has fixed bugs in issues #1234 and #1235, wants to move them to testing.

**Input:**
```
Mode: bugfix
branch: fix/payment-validation
scheme: Payoo Merchant Sandbox
issue_numbers: 1234, 1235
recipient: Anh Đoàn|U6T100Q4S
reply_on_thread: none
description: Fix payment validation and error handling
project: rnd/ios/payoo-ios-app-merchant
```

**Planned Actions:**
```
1. Create pipeline for branch: fix/payment-validation
2. Move issue #1234 to testing (add label: status::totesting)
3. Move issue #1235 to testing (add label: status::totesting)
```

**MCP Tool Calls:**
```
1. mobile-mcp-server/gitlab-create-pipeline-for-branch
   scheme: Payoo Merchant Sandbox
   branchName: fix/payment-validation
   recipient: Anh Đoàn|U6T100Q4S
   replyOnThread: none
   description: Fix payment validation and error handling
   project: rnd/ios/payoo-ios-app-merchant

2. mobile-mcp-server/gitlab-manage-issue
   issueIid: 1234
   action: add-labels
   labels: ["status::totesting"]

3. mobile-mcp-server/gitlab-manage-issue
   issueIid: 1235
   action: add-labels
   labels: ["status::totesting"]
```

## Example 2: Delivery Mode

**Scenario**: User completed issues #1236 and #1237, wants to close them with estimates.

**Input:**
```
Mode: delivery
branch: feature/smart-otp
scheme: Payoo Merchant Sandbox
issue_numbers: 1236, 1237
recipient: Huy Vũ|U03UJ8026RZ
reply_on_thread: none
description: SmartOTP feature delivery
estimates: 8h, 4h
project: rnd/ios/payoo-ios-app-merchant
```

**Planned Actions:**
```
1. Create pipeline for branch: feature/smart-otp
2. Close issue #1236 with estimate: 8h
3. Close issue #1237 with estimate: 4h
```

**MCP Tool Calls:**
```
1. mobile-mcp-server/gitlab-create-pipeline-for-branch
   scheme: Payoo Merchant Sandbox
   branchName: feature/smart-otp
   recipient: Huy Vũ|U03UJ8026RZ
   replyOnThread: none
   description: SmartOTP feature delivery
   project: rnd/ios/payoo-ios-app-merchant

2. mobile-mcp-server/gitlab-close-task
   taskId: 1236
   estimates: 8h

3. mobile-mcp-server/gitlab-close-task
   taskId: 1237
   estimates: 4h
```

## Example 3: Develop Mode

**Scenario**: User completed development of issue #1238, wants to create develop task and move original to testing.

**Input:**
```
Mode: develop
branch: develop
scheme: Payoo Merchant Sandbox
issue_numbers: 1238
recipient: Liên Trương|U01BP9QNURJ
reply_on_thread: none
description: New authentication flow
estimates: 16h
project: rnd/ios/payoo-ios-app-merchant
```

**Planned Actions:**
```
1. Create pipeline for branch: develop
2. Get issue #1238 details
3. Create develop task: "{original_title} [Develop]"
4. Move original issue #1238 to testing (add label: status::totesting)
5. Close develop task with estimate: 16h
```

**MCP Tool Calls:**
```
1. mobile-mcp-server/gitlab-create-pipeline-for-branch
   scheme: Payoo Merchant Sandbox
   branchName: develop
   recipient: Liên Trương|U01BP9QNURJ
   replyOnThread: none
   description: New authentication flow
   project: rnd/ios/payoo-ios-app-merchant

2. mobile-mcp-server/gitlab-get-issue
   issueIid: 1238
   projectName: rnd/ios/payoo-ios-app-merchant
   format: detailed

3. mobile-mcp-server/gitlab-create-task-for-issue
   issueIid: 1238
   project: rnd/ios/payoo-ios-app-merchant
   title: "{original_title} [Develop]"
   assignee: {original_assignee}
   labels: {original_labels + ["status::done"]}
   startDate: {today}
   dueDate: {today}
   description: "Created for develop mode.\n\n{original_description}"

4. mobile-mcp-server/gitlab-manage-issue
   issueIid: 1238
   action: add-labels
   labels: ["status::totesting"]

5. mobile-mcp-server/gitlab-close-task
   taskId: {task_id_from_step_3}
   estimates: 16h
```

**Note**: Only the FIRST issue in issue_numbers is processed for develop mode.

## Example 4: Redelivery Mode

**Scenario**: Previous delivery failed, need to rebuild and send again without changing issue status.

**Input:**
```
Mode: redelivery
branch: feature/smart-otp
scheme: Payoo Merchant Sandbox
recipient: Vi Trần|ULG64G5E3
reply_on_thread: https://payoo.slack.com/archives/C123/p1234567890
description: Redelivery after fixing build issue
project: rnd/ios/payoo-ios-app-merchant
```

**Planned Actions:**
```
1. Create pipeline for branch: feature/smart-otp
```

**MCP Tool Calls:**
```
1. mobile-mcp-server/gitlab-create-pipeline-for-branch
   scheme: Payoo Merchant Sandbox
   branchName: feature/smart-otp
   recipient: Vi Trần|ULG64G5E3
   replyOnThread: https://payoo.slack.com/archives/C123/p1234567890
   description: Redelivery after fixing build issue
   project: rnd/ios/payoo-ios-app-merchant
```

**Output:**
```
✅ Pipeline created successfully. No issue management for redelivery.
```

## Error Handling Examples

### Example: Invalid Issue IID

**Scenario**: User provides issue #9999 which doesn't exist.

**Action:**
- Skip issue #9999
- Log warning: "Issue #9999 not found or inaccessible, skipping"
- Continue with remaining valid issues
- Show summary: "2/3 issues processed successfully, 1 skipped"

### Example: Validation Failure

**Scenario**: User provides 3 issue numbers but only 2 estimates.

**Action:**
- Abort before creating pipeline
- Show error: "Validation failed: 3 issues but 2 estimates provided"
- Request correction: "Please provide estimates matching issue count (e.g., '2h, 3h, 4h')"

### Example: Pipeline Creation Failed

**Scenario**: GitLab API returns error when creating pipeline.

**Action:**
- Abort workflow immediately
- Display error: "Pipeline creation failed: [error details]"
- Show what was NOT done: "Issue management actions were not performed"
- Suggest: "Check branch exists and you have permissions"
