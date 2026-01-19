# Env Template

Generate a `.env.example` file by scanning your codebase for environment variable usage.

## Usage

- `/env-template` - Scan codebase and generate `.env.example`
- `/env-template --output=.env.sample` - Custom output filename
- `/env-template --update` - Update existing template, preserving comments
- `/env-template --check` - Report missing vars without generating file

## Task

Parse options from: {{RAW_PROMPT}}

**Output file:** `--output` value or `.env.example`
**Mode:** `--update` (merge), `--check` (report only), or generate (default)

### 1. Detect Environment Variable Patterns

Scan for env var access patterns by language:

**JavaScript/TypeScript:**
```bash
rg "process\.env\.(\w+)" -o --no-filename | sort -u
rg "process\.env\[.(\w+).\]" -o --no-filename | sort -u
```

**Python:**
```bash
rg "os\.environ\.get\(['\"](\w+)" -o --no-filename | sort -u
rg "os\.environ\[['\"](\w+)" -o --no-filename | sort -u
rg "os\.getenv\(['\"](\w+)" -o --no-filename | sort -u
```

**Ruby:**
```bash
rg "ENV\[['\"](\w+)" -o --no-filename | sort -u
rg "ENV\.fetch\(['\"](\w+)" -o --no-filename | sort -u
```

**Go:**
```bash
rg "os\.Getenv\(['\"](\w+)" -o --no-filename | sort -u
```

**Docker/Shell:**
```bash
rg "^\s*(\w+)=" docker-compose*.yml .env* | grep -v "^#"
rg "\$\{?(\w+)\}?" Dockerfile* --type dockerfile
```

### 2. Analyze Each Variable

For each found variable, determine:

**Required vs Optional:**
- Has default value? → Optional
- Used in conditional? → Optional
- Used directly without fallback? → Required

```typescript
// Required - no fallback
const url = process.env.DATABASE_URL

// Optional - has default
const port = process.env.PORT || 3000

// Optional - checked before use
if (process.env.DEBUG) { ... }
```

**Category (infer from name and usage):**
- `DATABASE_*`, `DB_*`, `*_DSN` → Database
- `*_API_KEY`, `*_SECRET`, `*_TOKEN` → Secrets
- `*_URL`, `*_HOST`, `*_PORT` → Services
- `NODE_ENV`, `RAILS_ENV`, `APP_ENV` → Environment
- `LOG_*`, `DEBUG` → Logging
- `AWS_*`, `GCP_*`, `AZURE_*` → Cloud
- `REDIS_*`, `CACHE_*` → Cache
- `SMTP_*`, `MAIL_*`, `EMAIL_*` → Email

**Example value (safe placeholders):**
- URLs: `http://localhost:PORT` or `https://example.com`
- Keys/Secrets: `your-xxx-key-here` (NEVER real values)
- Booleans: `true` or `false`
- Numbers: Sensible defaults (3000 for PORT, etc.)

### 3. Check Existing Files

Read existing env files for context:
- `.env.example` - Existing template
- `.env.local.example` - Local overrides template
- `.env` (if exists) - For structure only, NEVER copy actual values

### 4. Generate Output

**Standard format:**
```bash
# =============================================================================
# Environment Configuration
# =============================================================================
# Copy this file to .env and fill in the values.
# Required variables are marked with [REQUIRED].
# =============================================================================

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------
# [REQUIRED] PostgreSQL connection string
DATABASE_URL=postgresql://user:password@localhost:5432/myapp_dev

# -----------------------------------------------------------------------------
# Authentication
# -----------------------------------------------------------------------------
# [REQUIRED] Secret key for signing JWTs (generate with: openssl rand -hex 32)
JWT_SECRET=your-secret-key-here

# Session duration in seconds (default: 86400 = 24 hours)
SESSION_TTL=86400

# -----------------------------------------------------------------------------
# External Services
# -----------------------------------------------------------------------------
# Stripe API keys (get from https://dashboard.stripe.com/apikeys)
STRIPE_PUBLIC_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx

# -----------------------------------------------------------------------------
# Feature Flags
# -----------------------------------------------------------------------------
# Enable debug logging
DEBUG=false

# Enable experimental features
ENABLE_BETA_FEATURES=false
```

### 5. Update Mode (--update)

If updating existing file:
1. Parse existing `.env.example`
2. Keep all existing comments and formatting
3. Add new variables at end of appropriate section
4. Mark removed variables (found in file but not in code):
   ```bash
   # [DEPRECATED] No longer used in codebase
   # OLD_VARIABLE=value
   ```

### 6. Check Mode (--check)

Report without generating:

```markdown
## Environment Variable Audit

### Missing from .env.example
These are used in code but not documented:

| Variable | Files | Required |
|----------|-------|----------|
| `NEW_API_KEY` | src/api.ts:15, src/client.ts:8 | Yes |
| `FEATURE_X` | src/flags.ts:22 | No |

### Potentially Unused
In .env.example but not found in code:
- `OLD_DATABASE_URL`
- `LEGACY_API_KEY`

### Secrets in Code (WARNING)
Possible hardcoded secrets found:
- `src/config.ts:12` - Contains string matching API key pattern
```

## Security Rules

**NEVER include:**
- Actual secret values
- Production URLs or endpoints
- Real API keys (even test keys can be sensitive)
- Internal hostnames or IPs

**Always use:**
- Placeholder patterns: `your-xxx-here`, `xxx_test_xxx`
- `localhost` for local development URLs
- Example domains: `example.com`, `test.example.com`

## Quality Checklist

- [ ] All code-referenced env vars included
- [ ] Required vs optional correctly identified
- [ ] Variables grouped by category
- [ ] Comments explain purpose of each variable
- [ ] Placeholder values are safe (no real secrets)
- [ ] Generation instructions included where helpful
- [ ] Deprecated variables marked if using --update
