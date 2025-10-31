# MCP Tool Generator Examples

Complete examples of generated MCP tools following the standardized patterns. Includes simple CRUD tools, multi-action tools, and complex operation tools.

## Example 1: Simple CRUD - Get Merge Request Details

**Tool Type**: Simple CRUD (Pattern A)

### User Request
"Create a tool to get merge request details by IID"

### Generated File: `src/tools/gitlab/gitlab-get-merge-request.ts`

```typescript
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp';
import { z } from 'zod';
import { cleanGitLabHtmlContent } from '../../core/utils';
import { getGitLabService, getProjectNameFromUser } from './gitlab-shared';

export function registerGetMergeRequest(server: McpServer) {
    server.registerTool(
        "gitlab-get-merge-request",
        {
            title: "Get Merge Request Details",
            description: "Retrieve detailed information for a specific merge request by IID in a GitLab project. Returns merge request metadata including title, description, state, author, assignee, reviewers, labels, milestone, source/target branches, and approval status. Use this when you need comprehensive information about a specific merge request.",
            inputSchema: {
                mergeRequestIid: z.number().describe("The internal ID (IID) of the merge request to retrieve"),
                projectname: z.string().optional().describe("GitLab project name (if not provided, you'll be prompted to select)"),
                format: z.enum(["detailed", "concise"]).optional().describe("Response format - 'detailed' includes all metadata, 'concise' includes only key information")
            }
        },
        async ({ mergeRequestIid, projectname, format = "detailed" }) => {
            const iid = mergeRequestIid as number;
            try {
                const projectName = projectname || await getProjectNameFromUser(server, false, "Please select the project for getting merge request");
                if (!projectName) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: "Project not found or not selected. Please provide a valid project name." }) }] };
                }

                const service = await getGitLabService(server);
                const projectId = await service.getProjectId(projectName);
                if (!projectId) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Could not find project "${projectName}". Please verify the project name is correct and you have access to it.` }) }] };
                }

                const rawMr = await service.getMergeRequest(projectId, iid);
                if (!rawMr) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Merge request !${iid} not found in project "${projectName}". Please verify the merge request IID is correct.` }) }] };
                }

                // Clean HTML content from merge request fields
                const mr = cleanGitLabHtmlContent(rawMr, ['description', 'title']);

                // Format response based on requested format
                if (format === "concise") {
                    const conciseInfo = {
                        title: mr.title,
                        state: mr.state,
                        author: mr.author?.name || "Unknown",
                        assignee: mr.assignee?.name || "Unassigned",
                        labels: mr.labels || [],
                        milestone: mr.milestone?.title || "No milestone",
                        source_branch: mr.source_branch,
                        target_branch: mr.target_branch,
                        web_url: mr.web_url
                    };
                    return { content: [{ type: "text", text: `🔍 MR !${iid}: ${mr.title}\n📊 Status: ${mr.state}\n👤 Author: ${conciseInfo.author}\n👤 Assignee: ${conciseInfo.assignee}\n🏷️ Labels: ${conciseInfo.labels.join(', ') || 'None'}\n🎯 Milestone: ${conciseInfo.milestone}\n🔀 ${conciseInfo.source_branch} → ${conciseInfo.target_branch}\n🔗 URL: ${mr.web_url}` }] };
                }

                return { content: [{ type: "text", text: JSON.stringify(mr, null, 2) }] };
            } catch (e) {
                return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Error retrieving merge request !${iid}: ${String(e)}. Please check your GitLab connection and permissions.` }) }] };
            }
        }
    );
}
```

### Registration in `gitlab-tool.ts`

```typescript
import { registerGetMergeRequest } from './gitlab/gitlab-get-merge-request';

export function registerGitlabTools(server: McpServer) {
    // ... other registrations
    registerGetMergeRequest(server);
}
```

---

## Example 2: Multi-Action Tool - Manage Issues

**Tool Type**: Multi-Action (Pattern B)

### User Request
"Create a tool that can manage issues - get details, close, reopen, add labels, set assignees, and set due dates"

### Generated File: `src/tools/gitlab/gitlab-manage-issue.ts`

```typescript
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp';
import fetch from 'node-fetch';
import { z } from 'zod';
import { cleanGitLabHtmlContent } from '../../core/utils';
import { getGitLabService, getProjectNameFromUser } from './gitlab-shared';

export function registerManageIssue(server: McpServer) {
    server.registerTool(
        "gitlab-manage-issue",
        {
            title: "Manage GitLab Issue",
            description: "Comprehensive issue management tool that can get, update, or modify issues in a single operation. More efficient than using multiple separate tools. Supports getting issue details, updating status, adding labels, setting assignees, and modifying due dates.",
            inputSchema: {
                issueIid: z.number().describe("The internal ID (IID) of the issue to manage"),
                projectname: z.string().optional().describe("GitLab project name (if not provided, you'll be prompted to select)"),
                action: z.enum(["get", "close", "reopen", "add-labels", "set-assignee", "set-due-date"]).describe("Action to perform on the issue"),
                // Parameters for different actions
                labels: z.array(z.string()).optional().describe("For add-labels action: labels to add to the issue. Square brackets [] are allowed in label names."),
                assignee_username: z.string().optional().describe("For set-assignee action: username to assign the issue to"),
                due_date: z.string().optional().describe("For set-due-date action: due date in YYYY-MM-DD format")
            }
        },
        async ({ issueIid, projectname, action, labels, assignee_username, due_date }) => {
            const iid = issueIid as number;
            try {
                const projectName = projectname || await getProjectNameFromUser(server, false, "Please select the project for issue management");
                if (!projectName) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: "Project not found or not selected. Please provide a valid project name." }) }] };
                }

                const service = await getGitLabService(server);
                const projectId = await service.getProjectId(projectName);
                if (!projectId) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Could not find project "${projectName}". Please verify the project name is correct and you have access to it.` }) }] };
                }

                // Get issue first for all actions
                const rawIssue = await service.getIssue(projectId, iid);
                if (!rawIssue) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Issue #${iid} not found in project "${projectName}". Please verify the issue IID is correct.` }) }] };
                }

                // Clean HTML content from issue fields
                const issue = cleanGitLabHtmlContent(rawIssue, ['description', 'title']);

                switch (action) {
                    case "get":
                        return { content: [{ type: "text", text: JSON.stringify({
                            status: 'success',
                            action: 'get',
                            issue: {
                                id: issue.id,
                                iid: issue.iid,
                                title: issue.title,
                                webUrl: issue.web_url,
                                state: issue.state,
                                assignee: issue.assignee?.name || null,
                                labels: issue.labels || [],
                                milestone: issue.milestone?.title || null,
                                dueDate: issue.due_date || null,
                                description: issue.description
                            }
                        }, null, 2) }] };

                    case "close":
                        const closeResponse = await fetch(`${service.gitlabUrl}/api/v4/projects/${projectId}/issues/${iid}`, {
                            method: 'PUT',
                            headers: service['getHeaders'](),
                            body: JSON.stringify({ state_event: "close" })
                        });
                        if (!closeResponse.ok) {
                            return { content: [{ type: "text", text: JSON.stringify({
                                status: 'failure',
                                action: 'close',
                                error: `Failed to close issue #${iid}. Status: ${closeResponse.status}`,
                                issue: { id: issue.id, iid: issue.iid, title: issue.title, webUrl: issue.web_url }
                            }, null, 2) }] };
                        }
                        const closedIssue = await closeResponse.json();
                        return { content: [{ type: "text", text: JSON.stringify({
                            status: 'success',
                            action: 'close',
                            message: `Issue #${iid} has been closed successfully`,
                            issue: {
                                id: closedIssue.id,
                                iid: closedIssue.iid,
                                title: closedIssue.title,
                                webUrl: closedIssue.web_url,
                                state: closedIssue.state
                            }
                        }, null, 2) }] };

                    case "add-labels":
                        if (!labels || labels.length === 0) {
                            return { content: [{ type: "text", text: JSON.stringify({
                                status: 'failure',
                                action: 'add-labels',
                                error: "No labels provided. Please specify labels to add using the 'labels' parameter.",
                                issue: { id: issue.id, iid: issue.iid, title: issue.title, webUrl: issue.web_url }
                            }, null, 2) }] };
                        }
                        const currentLabels = issue.labels || [];
                        const newLabels = [...new Set([...currentLabels, ...labels])];
                        const labelsResponse = await fetch(`${service.gitlabUrl}/api/v4/projects/${projectId}/issues/${iid}`, {
                            method: 'PUT',
                            headers: service['getHeaders'](),
                            body: JSON.stringify({ labels: newLabels.join(',') })
                        });
                        if (!labelsResponse.ok) {
                            return { content: [{ type: "text", text: JSON.stringify({
                                status: 'failure',
                                action: 'add-labels',
                                error: `Failed to add labels. Status: ${labelsResponse.status}`,
                                issue: { id: issue.id, iid: issue.iid, title: issue.title, webUrl: issue.web_url }
                            }, null, 2) }] };
                        }
                        const labeledIssue = await labelsResponse.json();
                        return { content: [{ type: "text", text: JSON.stringify({
                            status: 'success',
                            action: 'add-labels',
                            message: `Added labels to issue #${iid}`,
                            addedLabels: labels,
                            issue: {
                                id: labeledIssue.id,
                                iid: labeledIssue.iid,
                                title: labeledIssue.title,
                                webUrl: labeledIssue.web_url,
                                labels: labeledIssue.labels
                            }
                        }, null, 2) }] };

                    default:
                        return { content: [{ type: "text", text: JSON.stringify({
                            status: 'failure',
                            action: action,
                            error: `Unknown action "${action}"`
                        }, null, 2) }] };
                }
            } catch (e) {
                return { content: [{ type: "text", text: JSON.stringify({
                    status: 'failure',
                    error: `Error managing issue #${iid}: ${String(e)}`
                }, null, 2) }] };
            }
        }
    );
}
```

---

## Example 3: Complex Operation - Review Merge Request Code

**Tool Type**: Complex Operation (Pattern C)

### User Request
"Create a tool to add inline code review comments on merge requests with position tracking and duplicate detection"

### Generated File: `src/tools/gitlab/gitlab-review-merge-request-code.ts`

```typescript
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp';
import { z } from 'zod';
import { getGitLabService } from './gitlab-shared';

export function registerReviewMergeRequestCode(server: McpServer) {
    server.registerTool(
        "gitlab-review-merge-request-code",
        {
            title: "Review Merge Request Code",
            description: "Add or update a code review comment on a merge request at a specific file and line position. This tool is designed for inline code reviews - it intelligently updates existing comments at the same position instead of creating duplicates. Requires diff SHA references (base, start, head) and file path with optional line numbers.",
            inputSchema: {
                projectId: z.number().describe("The project ID"),
                mrIid: z.number().describe("The merge request IID"),
                body: z.string().describe("The review comment body. Square brackets [] are allowed and commonly used in code references, markdown links, and examples."),
                positionType: z.string().default("text").describe("Position type (text, image, etc.)"),
                baseSha: z.string().describe("Base SHA for the diff"),
                startSha: z.string().describe("Start SHA for the diff"),
                headSha: z.string().describe("Head SHA for the diff"),
                newPath: z.string().describe("Path to the file being reviewed. Square brackets [] are allowed in file paths."),
                newLine: z.number().optional().describe("Line number in the new file (for line comments)"),
                oldPath: z.string().optional().describe("Path to the old file (defaults to newPath). Square brackets [] are allowed in file paths."),
                oldLine: z.number().optional().describe("Line number in the old file (for line comments)")
            }
        },
        async ({ projectId, mrIid, body, positionType, baseSha, startSha, headSha, newPath, newLine, oldPath, oldLine }) => {
            const pid = projectId as number;
            const iid = mrIid as number;
            const commentBody = body as string;
            const posType = positionType as string;
            const base = baseSha as string;
            const start = startSha as string;
            const head = headSha as string;
            const path = newPath as string;
            const line = newLine as number | undefined;
            const oldFilePath = (oldPath as string | undefined) || path;
            const oldFileLine = oldLine as number | undefined;

            try {
                const service = await getGitLabService(server);

                // Get existing discussions to check for existing review comments
                const discussions = await service.getMrDiscussions(String(pid), iid);

                // Find existing review comment at the same position
                let existingDiscussion = null;
                let existingNote = null;

                for (const discussion of discussions) {
                    if (discussion.notes && discussion.notes.length > 0) {
                        const firstNote = discussion.notes[0];

                        // Check if the position matches our target position
                        if (firstNote.position &&
                            firstNote.position.new_path === path &&
                            firstNote.position.base_sha === base &&
                            firstNote.position.head_sha === head &&
                            firstNote.position.start_sha === start) {

                            // Check if line position matches (if specified)
                            const positionMatches = line !== undefined ?
                                firstNote.position.new_line === line :
                                !firstNote.position.new_line;

                            if (positionMatches) {
                                existingDiscussion = discussion;
                                existingNote = firstNote;
                                break;
                            }
                        }
                    }
                }

                let result;

                if (existingNote && existingDiscussion) {
                    // Update existing comment
                    result = await service.updateMrDiscussionNote(
                        String(pid),
                        iid,
                        existingDiscussion.id,
                        existingNote.id,
                        commentBody
                    );

                    return {
                        content: [{
                            type: "text",
                            text: JSON.stringify({
                                action: "updated",
                                discussion_id: existingDiscussion.id,
                                note_id: existingNote.id,
                                updated_note: result
                            })
                        }]
                    };
                } else {
                    // Create new comment
                    const position: any = {
                        position_type: posType,
                        base_sha: base,
                        start_sha: start,
                        head_sha: head,
                        new_path: path,
                        old_path: oldFilePath
                    };

                    if (line !== undefined) {
                        position.new_line = line;
                    }

                    if (oldFileLine !== undefined) {
                        position.old_line = oldFileLine;
                    }

                    const data = { body: commentBody, position };
                    result = await service.addMrComments(String(pid), iid, data);

                    return {
                        content: [{
                            type: "text",
                            text: JSON.stringify({
                                action: "created",
                                discussion: result
                            })
                        }]
                    };
                }
            } catch (e) {
                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({ type: "error", error: String(e) })
                    }]
                };
            }
        }
    );
}
```

---

## Example 4: Simple CRUD - List Pipelines

**Tool Type**: Simple CRUD (Pattern A)

### User Request
"I need a tool to list all pipelines with status filtering and pagination"

### Generated File: `src/tools/gitlab/gitlab-list-pipelines.ts`

```typescript
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp';
import { z } from 'zod';
import { cleanGitLabHtmlContent } from '../../core/utils';
import { getGitLabService, getProjectNameFromUser } from './gitlab-shared';

export function registerListPipelines(server: McpServer) {
    server.registerTool(
        "gitlab-list-pipelines",
        {
            title: "List Pipelines",
            description: "Retrieve a list of pipelines for a GitLab project. Supports filtering by ref (branch/tag), status, and pagination. Returns pipeline information including ID, status, ref, commit details, and timestamps. Use this to monitor CI/CD pipeline execution, check build status, or find specific pipeline runs.",
            inputSchema: {
                projectname: z.string().optional().describe("GitLab project name (if not provided, you'll be prompted to select)"),
                ref: z.string().optional().describe("Filter pipelines by git reference (branch or tag name, e.g., 'main', 'develop')"),
                status: z.enum(["running", "pending", "success", "failed", "canceled", "skipped", "manual"]).optional().describe("Filter pipelines by status"),
                page: z.number().optional().describe("Page number for pagination (default: 1)"),
                perPage: z.number().optional().describe("Number of pipelines per page (default: 20, max: 100)"),
                format: z.enum(["detailed", "concise"]).optional().describe("Response format - 'detailed' includes all metadata, 'concise' includes only key information")
            }
        },
        async ({ projectname, ref, status, page = 1, perPage = 20, format = "detailed" }) => {
            try {
                const projectName = projectname || await getProjectNameFromUser(server, false, "Please select the project for listing pipelines");
                if (!projectName) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: "Project not found or not selected. Please provide a valid project name." }) }] };
                }

                const service = await getGitLabService(server);
                const projectId = await service.getProjectId(projectName);
                if (!projectId) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Could not find project "${projectName}". Please verify the project name is correct and you have access to it.` }) }] };
                }

                const options: any = { page, per_page: perPage };
                if (ref) options.ref = ref;
                if (status) options.status = status;

                const rawPipelines = await service.getPipelines(projectId, options);
                if (!rawPipelines || rawPipelines.length === 0) {
                    return { content: [{ type: "text", text: JSON.stringify({ type: "info", message: `No pipelines found in project "${projectName}" with the specified filters.` }) }] };
                }

                const pipelines = rawPipelines.map(p => cleanGitLabHtmlContent(p, []));

                if (format === "concise") {
                    const summary = pipelines.map(p =>
                        `📋 Pipeline #${p.id} | ${p.status} | ${p.ref} | ${new Date(p.created_at).toLocaleDateString()}`
                    ).join('\n');
                    return { content: [{ type: "text", text: `📋 Found ${pipelines.length} pipeline(s) in "${projectName}":\n\n${summary}` }] };
                }

                return { content: [{ type: "text", text: JSON.stringify(pipelines, null, 2) }] };
            } catch (e) {
                return { content: [{ type: "text", text: JSON.stringify({ type: "error", error: `Error listing pipelines: ${String(e)}. Please check your GitLab connection and permissions.` }) }] };
            }
        }
    );
}
```

---

## Common Patterns Summary

### Tool Pattern Selection Guide

| Tool Type | When to Use | Key Features | Example |
|-----------|-------------|--------------|---------|
| **Simple CRUD** | Single operation on resource | projectname, format, emojis | `gitlab-get-issue` |
| **Multi-Action** | Multiple operations on same resource | action enum, structured responses | `gitlab-manage-issue` |
| **Complex** | Advanced logic, discussions, position-based | Custom parameters, specialized logic | `gitlab-review-merge-request-code` |

### Response Format Patterns

**Simple CRUD - Concise**:
```typescript
if (format === "concise") {
    return { content: [{ type: "text", text:
        `🔍 Resource #${id}: ${title}\n` +
        `📊 Status: ${state}\n` +
        `🔗 URL: ${web_url}`
    }] };
}
```

**Multi-Action - Structured**:
```typescript
return { content: [{ type: "text", text: JSON.stringify({
    status: 'success',
    action: 'close',
    message: 'Issue closed successfully',
    issue: { /* key fields */ }
}, null, 2) }] };
```

**Complex - Custom**:
```typescript
return { content: [{ type: "text", text: JSON.stringify({
    action: "updated",
    discussion_id: "...",
    updated_note: {...}
}) }] };
```

### Error Handling Pattern

```typescript
try {
    // Operation logic
} catch (e) {
    // Simple CRUD
    return { content: [{ type: "text", text: JSON.stringify({
        type: "error",
        error: `Error: ${String(e)}`
    }) }] };

    // Multi-Action
    return { content: [{ type: "text", text: JSON.stringify({
        status: 'failure',
        error: `Error: ${String(e)}`
    }, null, 2) }] };
}
```

---

## Tool Comparison Table

| Feature | Simple CRUD | Multi-Action | Complex |
|---------|-------------|--------------|---------|
| projectname param | ✅ Optional | ✅ Optional | ❌ May use projectId |
| format param | ✅ Required | ❌ Not used | ❌ Not used |
| action enum | ❌ Not used | ✅ Required | ❌ Custom |
| Emoji output | ✅ Concise format | ❌ Not used | ❌ Not used |
| HTML cleaning | ✅ Always | ✅ Always | ⚠️ If applicable |
| Response type | JSON or text | Structured JSON | Custom |
| Direct fetch API | ❌ Use service | ✅ Often used | ✅ If needed |
| Complexity | Low | Medium | High |

---

**All examples follow the project's standardized patterns and conventions from CLAUDE.md!**
