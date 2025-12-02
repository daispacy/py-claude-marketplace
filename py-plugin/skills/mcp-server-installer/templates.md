# MCP Server Configuration Templates

## Template 1: stdio Transport (Local Command)

Most common type for npx, node, or local executables.

### Basic stdio Server

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": [
        "@package/mcp-server@latest"
      ]
    }
  }
}
```

### stdio Server with Environment Variables

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": [
        "@package/mcp-server@latest"
      ],
      "env": {
        "API_KEY": "${API_KEY}",
        "DATABASE_URL": "${DATABASE_URL:-sqlite://local.db}"
      }
    }
  }
}
```

### stdio Server with envFile Reference

```json
{
  "mcpServers": {
    "mobile-mcp-server": {
      "command": "npx",
      "args": [
        "@daipham/mobile-mcp-server@latest"
      ],
      "envFile": "${workspaceFolder}/.env"
    }
  }
}
```

### stdio Server with Custom Path

```json
{
  "mcpServers": {
    "custom-server": {
      "command": "/usr/local/bin/custom-server",
      "args": [
        "--port",
        "3000",
        "--config",
        "${HOME}/.config/server.json"
      ]
    }
  }
}
```

## Template 2: HTTP Transport (Remote Server)

For servers running on remote hosts or different ports.

### Basic HTTP Server

```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "https://api.example.com/mcp"
    }
  }
}
```

### HTTP Server with Authentication

```json
{
  "mcpServers": {
    "authenticated-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}",
        "X-Client-Version": "1.0.0"
      }
    }
  }
}
```

### HTTP Server with Multiple Headers

```json
{
  "mcpServers": {
    "enterprise-server": {
      "type": "http",
      "url": "${MCP_URL}",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}",
        "X-Organization": "${ORG_ID}",
        "X-Environment": "${ENVIRONMENT:-production}"
      }
    }
  }
}
```

## Template 3: SSE Transport (Server-Sent Events)

Deprecated but still supported for backward compatibility.

### Basic SSE Server

```json
{
  "mcpServers": {
    "sse-server": {
      "type": "sse",
      "url": "https://api.example.com/sse"
    }
  }
}
```

### SSE Server with Headers

```json
{
  "mcpServers": {
    "sse-authenticated": {
      "type": "sse",
      "url": "${SSE_URL}",
      "headers": {
        "Authorization": "Bearer ${SSE_TOKEN}"
      }
    }
  }
}
```

## Template 4: Complete Configuration File

Example of a complete `.mcp.json` with multiple servers:

```json
{
  "mcpServers": {
    "mobile-mcp-server": {
      "command": "npx",
      "args": [
        "@daipham/mobile-mcp-server@latest"
      ],
      "envFile": "${workspaceFolder}/.env"
    },
    "database-server": {
      "command": "node",
      "args": [
        "/usr/local/bin/db-mcp-server"
      ],
      "env": {
        "DB_HOST": "${DB_HOST:-localhost}",
        "DB_PORT": "${DB_PORT:-5432}",
        "DB_NAME": "${DB_NAME}"
      }
    },
    "api-server": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

## Environment Variable Syntax

### Required Variable
```json
"${VAR_NAME}"
```
Will error if VAR_NAME is not set.

### Optional Variable with Default
```json
"${VAR_NAME:-default_value}"
```
Uses `default_value` if VAR_NAME is not set.

### Common Environment Variables

**Workspace references:**
- `${workspaceFolder}` - Current workspace root directory
- `${HOME}` - User home directory
- `${USER}` - Current username

**API credentials:**
- `${API_KEY}` - API authentication key
- `${API_TOKEN}` - API authentication token
- `${API_SECRET}` - API secret

**URLs and endpoints:**
- `${API_URL}` - API base URL
- `${API_BASE_URL}` - API base URL
- `${MCP_URL}` - MCP server URL

**Database:**
- `${DATABASE_URL}` - Full database connection string
- `${DB_HOST}` - Database host
- `${DB_PORT}` - Database port
- `${DB_NAME}` - Database name
- `${DB_USER}` - Database username
- `${DB_PASSWORD}` - Database password

## Common Command Patterns

### NPM Package (npx)
```json
"command": "npx",
"args": ["@package/name@latest"]
```

### Node Script
```json
"command": "node",
"args": ["/path/to/script.js"]
```

### Python Script
```json
"command": "python",
"args": ["-m", "module_name"]
```

### Custom Binary
```json
"command": "/usr/local/bin/binary-name",
"args": ["--flag", "value"]
```

### UV (Python Package Manager)
```json
"command": "uvx",
"args": ["package-name"]
```

## Merging Strategy

When adding a new server to existing configuration:

1. **Read existing file**: Parse current `.mcp.json`
2. **Validate structure**: Ensure `mcpServers` object exists
3. **Check for duplicates**: Warn if server name already exists
4. **Merge configurations**: Add new server to `mcpServers` object
5. **Preserve formatting**: Maintain 2-space indentation
6. **Write atomically**: Write to temp file, then move to prevent corruption

### Example Merge

**Before:**
```json
{
  "mcpServers": {
    "existing-server": {
      "command": "node",
      "args": ["server.js"]
    }
  }
}
```

**After adding "new-server":**
```json
{
  "mcpServers": {
    "existing-server": {
      "command": "node",
      "args": ["server.js"]
    },
    "new-server": {
      "command": "npx",
      "args": ["@package/new-server@latest"]
    }
  }
}
```
