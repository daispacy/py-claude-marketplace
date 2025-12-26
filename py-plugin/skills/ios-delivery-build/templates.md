# Templates and Predefined Data

## Predefined Recipients

Use these exact format strings when asking user to select recipient:

- Anh Đoàn|U6T100Q4S
- Huy Vũ|U03UJ8026RZ
- Liên Trương|U01BP9QNURJ
- Vi Trần|ULG64G5E3

## Form Templates

### For Modes: develop, delivery, bugfix

```
branch: {current_branch}
scheme: Payoo Merchant Sandbox
issue_numbers: 123, 456
recipient: Anh Đoàn|U6T100Q4S
reply_on_thread: none
description: Fix authentication and payment bugs
estimates: 2h, 3h
project: rnd/ios/payoo-ios-app-merchant
```

**Field Descriptions:**
- **branch**: Git branch for pipeline (pre-filled)
- **scheme**: Build scheme (default shown)
- **issue_numbers**: Comma-separated GitLab issue IIDs
- **recipient**: Select from predefined list above
- **reply_on_thread**: Slack thread URL or "none"
- **description**: Pipeline description
- **estimates**: Comma-separated time estimates matching issue order (e.g., "2h, 1h, 3h")
- **project**: GitLab project path

### For Mode: redelivery

```
branch: {current_branch}
scheme: Payoo Merchant Sandbox
recipient: Anh Đoàn|U6T100Q4S
reply_on_thread: none
description: Redelivery for {reason}
project: rnd/ios/payoo-ios-app-merchant
```

**Note**: No issue_numbers or estimates needed for redelivery.

## Parsing Instructions

**issue_numbers and estimates:**
- Split by comma: "123, 456, 789" → ["123", "456", "789"]
- Trim whitespace from each element
- Validate numeric for issue_numbers
- Ensure estimates match issue count (for delivery/develop modes)

**recipient format:**
- Must match exactly: "Name|SlackID"
- Validate against predefined list
- Extract name and ID for MCP tool call

**reply_on_thread:**
- Accept "none" (lowercase)
- Or valid Slack thread URL format
- Default to "none" if not provided
