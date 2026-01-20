---
description: Quick security audit for common vulnerabilities and leaked secrets
---

# Security Scan

Quick security audit of your code for common vulnerabilities.

## Usage

- `/security-scan` - Scan entire codebase
- `/security-scan --staged` - Only scan staged changes (pre-commit)
- `/security-scan --diff=main` - Scan changes vs branch
- `/security-scan src/api` - Scan specific directory
- `/security-scan --severity=high` - Only high/critical issues

## Task

Parse options from: {{RAW_PROMPT}}

### 1. Determine Scope

**Full scan:** Scan all source files
**Staged:** `git diff --cached --name-only`
**Diff:** `git diff main...HEAD --name-only`
**Directory:** Only files in specified path

### 2. Secret Detection

Scan for hardcoded secrets:

```bash
# API keys (generic patterns)
rg -n "(api[_-]?key|apikey)\s*[:=]\s*['\"][a-zA-Z0-9]{16,}" -i

# AWS
rg -n "AKIA[0-9A-Z]{16}"
rg -n "aws.{0,20}secret.{0,20}['\"][0-9a-zA-Z/+]{40}['\"]" -i

# Private keys
rg -n "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"

# JWT/Bearer tokens
rg -n "(bearer|jwt)\s*[:=]\s*['\"][a-zA-Z0-9._-]{20,}['\"]" -i

# Database URLs with passwords
rg -n "(postgres|mysql|mongodb)://[^:]+:[^@]+@"

# Generic secrets
rg -n "(password|passwd|secret|token)\s*[:=]\s*['\"][^'\"]{8,}['\"]" -i

# .env files in repo
fd -H "^\.env$|\.env\.local$|\.env\.production$" --type f
```

### 3. Injection Vulnerabilities

**SQL Injection:**
```bash
# String concatenation in queries
rg -n "query\s*\(\s*[\"'\`].*\+.*\)" --type ts --type js
rg -n "execute\s*\(\s*f[\"']" --type py  # Python f-strings in SQL
rg -n '\.where\s*\(\s*".*#\{' --type ruby  # Ruby interpolation
```

**Command Injection:**
```bash
# Shell execution with variables
rg -n "exec\s*\(\s*[\"'\`].*\$\{" --type ts --type js
rg -n "child_process.*exec.*\+" --type ts --type js
rg -n "subprocess\.(run|call|Popen).*shell\s*=\s*True" --type py
rg -n "system\s*\(\s*[\"'].*#\{" --type ruby
```

**XSS:**
```bash
# Dangerous innerHTML
rg -n "dangerouslySetInnerHTML|innerHTML\s*=" --type tsx --type jsx --type ts --type js
rg -n "v-html\s*=" --type vue
rg -n "\|safe\s*}}" --type html  # Jinja/Django
rg -n "raw\s*%>" --type erb
```

### 4. Authentication/Authorization Issues

```bash
# Disabled security
rg -n "verify\s*[:=]\s*false" -i
rg -n "secure\s*[:=]\s*false" -i
rg -n "httpOnly\s*[:=]\s*false" -i

# Weak crypto
rg -n "md5|sha1\s*\(" -i
rg -n "Math\.random" --type ts --type js  # Not cryptographically secure

# Missing auth checks (heuristic: routes without auth middleware)
rg -n "app\.(get|post|put|delete)\s*\(['\"]" --type ts --type js
```

### 5. Dependency Vulnerabilities

```bash
# Check for known vulnerable packages
npm audit --json 2>/dev/null | head -100
```

### 6. Configuration Issues

```bash
# Debug mode in production configs
rg -n "debug\s*[:=]\s*true" -i -g "*.prod*" -g "*production*"

# CORS wildcards
rg -n "cors.*\*|Access-Control-Allow-Origin.*\*"

# Exposed ports
rg -n "0\.0\.0\.0" --type ts --type js --type py

# Default credentials
rg -n "(admin|root|test|password)\s*[:=]\s*['\"]" -g "*.config.*" -g "*.env*"
```

### 7. Generate Report

```markdown
## Security Scan Report

**Scope:** [Full codebase | Staged changes | Diff vs main]
**Files scanned:** 234
**Issues found:** 12

---

### 🔴 Critical (2)

#### Hardcoded AWS Credentials
**File:** `src/config/aws.ts:15`
**Type:** Secret Exposure
```typescript
const AWS_SECRET = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```
**Risk:** Credentials in source code can be extracted from version control history.
**Fix:** Use environment variables or a secrets manager.

#### SQL Injection
**File:** `src/api/users.ts:45`
**Type:** Injection
```typescript
db.query(`SELECT * FROM users WHERE id = ${userId}`)
```
**Risk:** Attacker can execute arbitrary SQL via `userId` parameter.
**Fix:** Use parameterized queries: `db.query('SELECT * FROM users WHERE id = $1', [userId])`

---

### 🟠 High (3)

#### Command Injection Risk
**File:** `src/utils/exec.ts:23`
**Type:** Injection
```typescript
exec(`convert ${filename} output.png`)
```
**Risk:** Filename could contain shell metacharacters.
**Fix:** Use `execFile` with argument array, or sanitize input.

#### XSS via dangerouslySetInnerHTML
**File:** `src/components/Comment.tsx:34`
**Type:** XSS
```tsx
<div dangerouslySetInnerHTML={{ __html: comment.body }} />
```
**Risk:** If `comment.body` contains user input, XSS is possible.
**Fix:** Sanitize with DOMPurify or use a markdown renderer.

---

### 🟡 Medium (4)

| File | Issue | Type |
|------|-------|------|
| `src/auth.ts:12` | MD5 used for hashing | Weak Crypto |
| `src/api/cors.ts:5` | CORS allows all origins | Configuration |
| `config/dev.js:8` | Debug mode enabled | Configuration |
| `src/utils/random.ts:3` | Math.random for tokens | Weak Crypto |

---

### 🟢 Low (3)

| File | Issue |
|------|-------|
| `package.json` | 3 low-severity npm audit findings |
| `src/logger.ts:45` | Logs may contain sensitive data |
| `.gitignore` | Missing common secret file patterns |

---

### ✅ Passed Checks

- No private keys found in repository
- No .env files committed
- HTTPS enforced in production config
- JWT tokens use secure algorithms

---

### 📋 Recommendations

**Immediate:**
1. Remove hardcoded AWS credentials from `src/config/aws.ts`
2. Fix SQL injection in `src/api/users.ts`
3. Rotate any exposed credentials

**Soon:**
1. Add input sanitization for shell commands
2. Sanitize user content before rendering HTML
3. Replace MD5 with bcrypt for password hashing

**Ongoing:**
1. Add secret scanning to CI/CD pipeline
2. Enable dependabot for dependency updates
3. Add security linting (eslint-plugin-security)

---

### 🔧 Automated Fixes Available

Run these commands to fix some issues automatically:

```bash
# Fix npm vulnerabilities
npm audit fix

# Add recommended .gitignore patterns
echo ".env*\n*.pem\n*.key" >> .gitignore
```
```

## Severity Classification

**Critical:**
- Hardcoded secrets/credentials
- SQL/Command injection with user input
- Authentication bypass

**High:**
- XSS vulnerabilities
- Injection risks (may need user input analysis)
- Weak cryptography for security functions

**Medium:**
- CORS misconfiguration
- Debug mode in production
- Missing security headers

**Low:**
- Informational findings
- Best practice suggestions
- Low-severity dependency issues

## Quality Checklist

- [ ] Secrets scan covers all common patterns
- [ ] Injection checks for all relevant languages
- [ ] No false positives in test files (exclude test dirs)
- [ ] Severity accurately reflects risk
- [ ] Fix suggestions are specific and actionable
- [ ] No sensitive data exposed in the report itself
