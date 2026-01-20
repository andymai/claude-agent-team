---
description: Audit dependencies for outdated packages and security vulnerabilities
---

# Check Dependencies

Audit dependencies for outdated packages, security vulnerabilities, and upgrade recommendations.

## Usage

- `/check-deps` - Full audit (outdated + security)
- `/check-deps --security` - Security vulnerabilities only
- `/check-deps --outdated` - Outdated packages only
- `/check-deps --major` - Only show major version updates
- `/check-deps lodash react` - Check specific packages

## Task

Parse options from: {{RAW_PROMPT}}

### 1. Detect Package Manager

Check for lock files:
- `package-lock.json` or `npm-shrinkwrap.json` → npm
- `yarn.lock` → yarn
- `pnpm-lock.yaml` → pnpm
- `bun.lockb` → bun
- `Gemfile.lock` → bundler
- `poetry.lock` or `Pipfile.lock` → poetry/pipenv
- `requirements.txt` → pip
- `go.sum` → go modules
- `Cargo.lock` → cargo

### 2. Check for Outdated Packages

**npm/yarn/pnpm:**
```bash
npm outdated --json 2>/dev/null || npm outdated
```

**bundler:**
```bash
bundle outdated
```

**pip:**
```bash
pip list --outdated --format=json
```

**cargo:**
```bash
cargo outdated -R
```

### 3. Security Audit

**npm:**
```bash
npm audit --json 2>/dev/null || npm audit
```

**yarn:**
```bash
yarn audit --json 2>/dev/null || yarn audit
```

**bundler:**
```bash
bundle audit check
```

**pip:**
```bash
pip-audit --format=json 2>/dev/null || pip-audit
```

**cargo:**
```bash
cargo audit --json 2>/dev/null || cargo audit
```

### 4. Analyze Results

For each outdated package, determine:

**Update Risk Level:**
- **Patch** (1.0.0 → 1.0.1): Low risk, typically safe
- **Minor** (1.0.0 → 1.1.0): Medium risk, new features, should be compatible
- **Major** (1.0.0 → 2.0.0): High risk, breaking changes likely

**Popularity/Maintenance:**
- Check if package is actively maintained
- Note if package is deprecated
- Flag if downloads are declining (abandoned)

**Changelog highlights:**
For major updates, briefly note key breaking changes if discoverable from npm/GitHub.

### 5. Generate Report

```markdown
## Dependency Audit Report

**Project:** [name from package.json/Gemfile/etc]
**Package Manager:** npm 10.2.0
**Total Dependencies:** 145 (32 direct, 113 transitive)

---

### 🚨 Security Vulnerabilities

#### Critical (1)

| Package | Vulnerability | Severity | Fixed In | Path |
|---------|--------------|----------|----------|------|
| `lodash` | Prototype Pollution (CVE-2021-23337) | Critical | 4.17.21 | lodash |

**Fix:** `npm audit fix` or `npm install lodash@4.17.21`

#### High (2)

| Package | Vulnerability | Severity | Fixed In |
|---------|--------------|----------|----------|
| `axios` | SSRF (CVE-2023-45857) | High | 1.6.0 |
| `semver` | ReDoS (CVE-2022-25883) | High | 7.5.2 |

---

### 📦 Outdated Packages

#### Major Updates (Breaking Changes Likely)

| Package | Current | Latest | Age | Notes |
|---------|---------|--------|-----|-------|
| `react` | 17.0.2 | 18.2.0 | 2y | Concurrent mode, new hooks |
| `typescript` | 4.9.5 | 5.3.2 | 1y | Decorators, const type params |

#### Minor Updates (New Features)

| Package | Current | Latest | Risk |
|---------|---------|--------|------|
| `express` | 4.18.0 | 4.18.2 | Low |
| `jest` | 29.5.0 | 29.7.0 | Low |

#### Patch Updates (Bug Fixes)

12 packages have patch updates available.
Run `npm update` to apply all safe patches.

---

### 📋 Recommendations

**Immediate (Security):**
1. `npm install lodash@4.17.21` - Critical vulnerability
2. `npm install axios@1.6.0 semver@7.5.2` - High vulnerabilities

**Soon (Maintenance):**
1. Update `typescript` to 5.x - Better performance, new features
2. Update `react` to 18.x - Plan migration, significant changes

**Low Priority:**
- Run `npm update` for 12 patch updates
- Consider `npm audit fix` for automatic fixes

---

### ⚠️ Warnings

- `request` is deprecated - migrate to `axios` or `node-fetch`
- `moment` is in maintenance mode - consider `date-fns` or `dayjs`
```

### 6. Specific Package Mode

If specific packages are requested (`/check-deps lodash react`):

Focus report on just those packages:
- Current version
- Latest version
- All versions in between with release dates
- Changelog summary
- Known vulnerabilities
- Migration guide link if major update

## Package Manager Commands Reference

| Task | npm | yarn | pnpm |
|------|-----|------|------|
| Outdated | `npm outdated` | `yarn outdated` | `pnpm outdated` |
| Audit | `npm audit` | `yarn audit` | `pnpm audit` |
| Fix | `npm audit fix` | `yarn audit fix` | `pnpm audit --fix` |
| Update all | `npm update` | `yarn upgrade` | `pnpm update` |
| Update one | `npm install pkg@latest` | `yarn add pkg@latest` | `pnpm add pkg@latest` |

## Quality Checklist

- [ ] Correct package manager detected
- [ ] Security vulnerabilities highlighted first
- [ ] Breaking changes clearly marked for major updates
- [ ] Actionable fix commands provided
- [ ] Deprecated packages flagged
- [ ] Recommendations prioritized by risk/impact
