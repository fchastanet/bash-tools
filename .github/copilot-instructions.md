# Copilot Instructions for bash-tools Repository

This document provides guidance for GitHub Copilot agents working on the
bash-tools repository. It covers the project architecture, conventions,
development workflow, and common troubleshooting steps.

## Project Overview

**bash-tools** is a collection of Bash utilities built on the
[Bash Tools Framework](https://github.com/fchastanet/bash-tools-framework). It
provides reusable bash scripts for database management, Git operations, Docker
utilities, and more.

### Key Tools Provided

- **Database**: `dbImport`, `dbQueryAllDatabases`, `dbScriptAllDatabases`,
  `dbImportProfile`, `dbImportStream`
- **Git**: `gitRenameBranch`, `gitIsAncestorOf`, `gitIsBranch`
- **GitHub**: `githubReleaseManager`, `upgradeGithubRelease`
- **Docker**: `cli` (container connection), `waitForIt`, `waitForMysql`
- **API**: `postmanCli` (Postman collection/environment management)
- **Converters**: `mysql2puml` (MySQL to PlantUML diagrams)

## Architecture & Build System

### Compilation Process

This project uses a **Bash Compiler** (external Go-based tool from
[fchastanet/bash-compiler](https://github.com/fchastanet/bash-compiler)) to
generate standalone executable scripts from modular source files.

#### Binary Structure

Each binary tool follows this structure in
`src/_binaries/{Category}/{Command}/`:

```text
{command}-binary.yaml  # Build configuration (extends shared definitions)
{command}-main.sh      # Main implementation logic
{command}-options.sh   # CLI option definitions and callbacks
{command}.bats         # Unit tests
testsData/             # Test fixtures and expected outputs
```

#### YAML Configuration

- **Build config**: `.bash-compiler` defines `FRAMEWORK_ROOT_DIR` and
  `BASH_TOOLS_ROOT_DIR`
- **Binary definitions**: YAML files extend shared option definitions from
  `src/_binaries/commandDefinitions/`
- **Priority includes**: Definition files use numbered keys (e.g., `20:`) to
  control include order
- **Output**: Compiled binaries are generated to `bin/` directory

#### Framework Configuration

- `.framework-config`: Defines project-wide environment variables
- Key variables:
  - `BASH_TOOLS_ROOT_DIR`: Project root
  - `FRAMEWORK_ROOT_DIR`: Path to bash-tools-framework vendor directory
  - `FRAMEWORK_SRC_DIRS`: Array of source directories to search
- Important: The `vendor/` directory contains the bash-tools-framework and is
  **not tracked in git** (see `.gitignore`)

### Compilation Command

To compile binaries:

```bash
(
    cd "${HOME}/fchastanet/bash-compiler" || exit 1
    go run ./cmd/bash-compiler -r "~/fchastanet/bash-tools/vendor/bash-tools-framework" "$@"
)
```

**Note**: Binaries are pre-compiled and checked into `bin/`.
**Note2**: `.bash-compiler` file is automatically loaded and used to configure the compiler.
It defines variables that the compiler reads to determine source directories and framework paths.

## Directory Structure

| Directory               | Purpose                                             |
| ----------------------- | --------------------------------------------------- |
| `src/_binaries/`        | Binary definitions and implementations by category  |
| `src/BashTools/`        | Core framework utilities and helpers                |
| `src/Db/`               | Database manipulation functions                     |
| `src/Postman/`          | Postman API/collection management                   |
| `src/InstallCallbacks/` | Dependency installation logic                       |
| `bin/`                  | **Compiled executable binaries** (tracked in git)   |
| `vendor/`               | External dependencies (not tracked, auto-installed) |
| `conf/`                 | Configuration file templates                        |
| `pages/`                | Docsify documentation website source                |
| `doc/`                  | Auto-generated documentation                        |
| `.github/`              | CI/CD workflows and GitHub configuration            |

## Testing

### Framework: BATS (Bash Automated Testing System)

- **Test files**: Suffix `.bats` (e.g., `gitIsBranch.bats`)
- **Location**: Co-located with source files (same directory as `.sh` files)
- **Libraries** (auto-installed to `vendor/`):
  - `bats-core`: Test runner
  - `bats-support` & `bats-assert`: Assertion helpers
  - `bats-mock`: Mocking framework
  - `tomdoc.sh`: Documentation generation

### Running Tests

```bash
# Install test dependencies first (if not already done)
./bin/installRequirements

# Run all tests in src directory
./test.sh scrasnups/build:bash-tools-ubuntu-5.3 -r src -j 30

# Run tests on different Bash versions
./test.sh scrasnups/build:bash-tools-ubuntu-4.4 -r src -j 30
./test.sh scrasnups/build:bash-tools-alpine-5.0 -r src -j 30

# Run specific test file
./test.sh scrasnups/build:bash-tools-ubuntu-5.3 src/_binaries/Git/gitIsBranch/gitIsBranch.bats
```

### Test Structure

Tests use this pattern:

```bash
#!/usr/bin/env bash

# Load test helpers
source "$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/batsHeaders.sh"

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR}"
  export HOME="${BATS_TEST_TMPDIR}/home"
  # Additional setup…
}

teardown() {
  unstub_all
}

function TestName::description { #@test
  # Test implementation
}
```

### Docker-Based Testing

Tests run inside Docker containers to ensure consistency across environments:

- Images: `scrasnups/build:bash-tools-{ubuntu|alpine}-{4.4|5.0|5.3}`
- Environment variables:
  - `KEEP_TEMP_FILES`: Set to `1` to preserve temp files for debugging
  - `BATS_FIX_TEST`: Set to `1` to auto-update test expectations
  - `CI_MODE`: Set to `1` in CI environment

## Linting & Code Quality

### Pre-commit Hooks

This project uses extensive pre-commit hooks configured in
`.pre-commit-config.yaml` and `.pre-commit-config-github.yaml`.

#### Installation

```bash
# Install pre-commit tool first (if not available)
pip install pre-commit

# Enable hooks
pre-commit install --hook-type pre-commit --hook-type pre-push
```

### Key Linters

| Tool           | Purpose                          | Config File              |
| -------------- | -------------------------------- | ------------------------ |
| **shellcheck** | Shell script static analysis     | `.shellcheckrc`          |
| **shfmt**      | Shell script formatting          | (embedded in pre-commit) |
| **yamllint**   | YAML validation                  | `.yamllint.yml`          |
| **prettier**   | Markdown/JSON/YAML formatting    | `.prettierrc.yaml`       |
| **mdformat**   | Markdown formatting with plugins | (in pre-commit config)   |
| **codespell**  | Spell checking                   | `cspell.yaml`            |
| **actionlint** | GitHub Actions validation        | (in pre-commit)          |

### ShellCheck Configuration

Key settings in `.shellcheckrc`:

- `external-sources=true`: Allow sourcing external files
- `enable=require-variable-braces`: Enforce `${var}` over `$var`
- `enable=require-double-brackets`: Enforce `[[ ]]` over `[ ]`
- `enable=avoid-nullary-conditions`: Catch common conditional errors
- `source-path=SCRIPTDIR`: Resolve sources relative to script directory
- `source-path=vendor/bash-tools-framework`: Include framework sources
- Excludes: `.bats`, `.tpl`, `/testsData/`, `.cache/pre-commit`

### MegaLinter

The CI runs MegaLinter (Terraform flavor) with additional checks. Configuration
in `.mega-linter-githubAction.yml`.

## Coding Conventions

### Naming Conventions

- **Binaries/Commands**: `kebab-case` (e.g., `git-is-branch`, `db-import`)
- **Functions**: `PascalCase::kebabCase` (e.g., `BashTools::runVerboseIfNeeded`,
  `Log::fatal`)
- **Variables**: `camelCase` for locals, `UPPER_CASE` for globals/exports
- **Files**: `{command}-{suffix}.sh` pattern

### Shell Script Standards

- **Shebang**: `#!/usr/bin/env bash`
- **Strict mode**: Scripts use `set -o errexit`, `set -o pipefail`,
  `set -o errtrace`
- **Variable expansion**: Always use `${var}` instead of `$var`
- **Conditionals**: Use `[[ ]]` instead of `[ ]`
- **Sourcing**: Use relative paths resolved via `$(cd … && pwd)` pattern
- **shellcheck disable**: Use specific codes and add explanatory comments

### File Patterns

Defined in `.framework-config`:

- **Non-framework files**: Match `NON_FRAMEWORK_FILES_REGEXP` (e.g., `.bats`,
  `testsData/`, `_binaries`)
- **No BATS needed**: Match `BATS_FILE_NOT_NEEDED_REGEXP` (e.g., config files,
  test data)
- **Function matching ignore**: Match
  `FRAMEWORK_FILES_FUNCTION_MATCHING_IGNORE_REGEXP`

## Development Workflow

### Initial Setup

```bash
# Clone repository
git clone git@github.com:fchastanet/bash-tools.git
cd bash-tools

# Run installation script (creates ~/.bash-tools structure)
./install

# Install test dependencies
./bin/installRequirements

# Install pre-commit hooks
pre-commit install --hook-type pre-commit --hook-type pre-push
```

### Making Changes

1. **Create/modify source files** in `src/_binaries/{Category}/{Command}/`:

   - `{command}-main.sh`: Implementation logic
   - `{command}-options.sh`: CLI option definitions
   - `{command}-binary.yaml`: Build configuration (if creating new command)

2. **Write/update tests** in corresponding `.bats` file

3. **Compile binaries** (if bash-compiler is available):

   ```bash
   # Usually binaries are pre-compiled, but if you need to rebuild:
   (
     cd "${HOME}/fchastanet/bash-compiler" || exit 1
     go run ./cmd/bash-compiler -r "~/fchastanet/bash-tools/vendor/bash-tools-framework" "$@"
   )
   ```

4. **Run tests**:

   ```bash
   ./test.sh scrasnups/build:bash-tools-ubuntu-5.3 -r src -j 30
   ```

5. **Run pre-commit checks**:

   ```bash
   pre-commit run --all-files
   ```

### Documentation

#### Auto-Generated Documentation

```bash
# Generate documentation from source code comments (tomdoc format)
./bin/doc
```

Documentation is generated from specially formatted comments in source files and
placed in the `doc/` and `pages/` directories.

#### GitHub Pages

The project uses Docsify for its documentation site:

```bash
# Install docsify CLI globally
npm i docsify-cli -g

# Serve documentation locally
docsify serve pages

# Navigate to http://localhost:3000/
```

## CI/CD Pipeline

### Workflows

Located in `.github/workflows/`:

1. **lint-test.yml**: Main CI pipeline

   - Runs pre-commit hooks and MegaLinter
   - Executes unit tests on multiple Bash versions (4.4, 5.0, 5.3)
   - Tests on Ubuntu and Alpine Linux
   - Auto-creates PRs for lint fixes

2. **docsify-gh-pages.yml**: Documentation deployment

3. **precommit-autoupdate.yml**: Auto-updates pre-commit hooks

### Test Matrix

Tests run on 6 combinations:

- **Vendors**: Ubuntu 20.04, Alpine 3.19
- **Bash versions**: 4.4, 5.0, 5.3
- **Parallelization**: `-j 30` (30 parallel test jobs)
- **Alpine-specific**: Excludes tests tagged `ubuntu_only`

### Artifacts

- **MegaLinter reports**: Uploaded as artifacts
- **Test results**: JUnit XML format in `logs/` directory
- **Build logs**: Bats output logs for debugging

## Common Issues & Troubleshooting

### Issue: Vendor Dependencies Not Found

**Symptom**: Error messages like "cannot find bash-tools-framework"

**Solution**:

```bash
# Install framework and test dependencies
./bin/installRequirements
vendor/bash-tools-framework/bin/installRequirements
```

The `vendor/` directory is not tracked in git and must be populated by running
installation scripts.

### Issue: ShellCheck Errors

**Symptom**: ShellCheck warnings/errors during pre-commit or CI

**Common fixes**:

- Ensure variable braces: `${var}` not `$var`
- Use double brackets: `[[ ]]` not `[ ]`
- Add `# shellcheck disable=SCxxxx` with explanation if warning is intentional

**ShellCheck source resolution**:

- Add `# shellcheck source=path/to/file` comment before sourcing
- Paths are resolved relative to `SCRIPTDIR` and `vendor/bash-tools-framework`

### Issue: BATS Tests Fail Locally But Pass in CI

**Likely causes**:

1. Different Bash version (test with specific Docker image)
2. Missing test dependencies (run `./bin/installRequirements`)
3. Stale temporary files (check `KEEP_TEMP_FILES` setting)

**Debug approach**:

```bash
# Run tests with same Docker image as CI
./test.sh scrasnups/build:bash-tools-ubuntu-5.3 -r src

# Keep temp files for inspection
KEEP_TEMP_FILES=1 ./test.sh scrasnups/build:bash-tools-ubuntu-5.3 path/to/test.bats

# Run specific test with verbose output
./test.sh scrasnups/build:bash-tools-ubuntu-5.3 path/to/test.bats -f "test-name"
```

### Issue: Pre-commit Hook Fails

**Symptom**: Pre-commit fails with timeout or hanging

**Solution**:

```bash
# Update pre-commit hooks to latest versions
pre-commit autoupdate

# Clear pre-commit cache
pre-commit clean

# Run specific hook to isolate issue
pre-commit run HOOK_ID --all-files

# Skip hooks temporarily (not recommended for final commit)
git commit --no-verify
```

### Issue: Binary Not Regenerated After Source Changes

**Understanding**: Binaries in `bin/` are **pre-compiled and tracked in git**.
Changes to source files in `src/` do not automatically update the binaries.

**Solution**: Binaries are typically compiled by the repository maintainer using
the bash-compiler tool. As a contributor:

1. Make changes to source files (`*-main.sh`, `*-options.sh`, `*-binary.yaml`)
2. Commiting files will use pre-commit hooks that
    - Run shellcheck on source files
    - Compile binaries (bash-compiler is made available by pre-commit hook)
    - Run tests against source files (not compiled binaries)
    - Ensure tests pass (tests can run against source files)
3. Submit PR with source changes

Never edit compiled binaries directly as they will be overwritten by the build process. Focus on modifying source files and ensuring tests pass.

### Issue: Documentation Not Updating

**Symptom**: Changes to source code comments not reflected in docs

**Solution**:

```bash
# Regenerate documentation from source
./bin/doc

# Check generated files in doc/ and pages/ directories
```

Documentation is generated from tomdoc-style comments in source files.

### Debugging BATS Tests

**Enable verbose output**:

```bash
# Run with bats verbose flag
./test.sh scrasnups/build:bash-tools-ubuntu-5.3 -t path/to/test.bats

# Run single test function
./test.sh scrasnups/build:bash-tools-ubuntu-5.3 path/to/test.bats -f "test-name"
```

**Preserve test files**:

```bash
KEEP_TEMP_FILES=1 ./test.sh scrasnups/build:bash-tools-ubuntu-5.3 path/to/test.bats
# Inspect files in BATS_TEST_TMPDIR (usually /tmp)
```

**Auto-fix test expectations**:

```bash
# Update expected output files automatically
BATS_FIX_TEST=1 ./test.sh scrasnups/build:bash-tools-ubuntu-5.3 path/to/test.bats
```

## Best Practices for Copilot Agents

### When Making Changes

1. **Minimal modifications**: Only change what's necessary to address the issue
2. **Test co-location**: Always create/update `.bats` file alongside source
   changes
3. **Follow naming conventions**: Use existing patterns for functions, files,
   variables
4. **Preserve structure**: Keep the binary yaml structure and extends hierarchy
5. **Run tests before committing**: Use `./test.sh` with appropriate Docker
   image
6. **Check ShellCheck**: Ensure changes pass shellcheck with project config
7. **Update docs if needed**: Regenerate docs with `./bin/doc` if function
   signatures change

### When Creating New Binaries

1. Create directory: `src/_binaries/{Category}/{CommandName}/`
2. Create files:
   - `{commandName}-binary.yaml` (extend appropriate base configs)
   - `{commandName}-main.sh` (implementation)
   - `{commandName}-options.sh` (CLI options and help)
   - `{commandName}.bats` (tests)
   - `testsData/` directory (test fixtures)
3. Follow existing examples (e.g., `src/_binaries/Git/gitIsBranch/`)
4. Note: Binary compilation requires bash-compiler tool (maintained separately)

### Understanding Dependencies

- **bash-tools-framework**: Core framework providing utility functions, must be
  in `vendor/bash-tools-framework`
- **Test libraries**: BATS and related tools, installed via
  `bin/installRequirements`
- **External tools**: Some commands require tools like GNU parallel, mysql
  client, etc.

### Avoiding Common Pitfalls

1. **Don't edit compiled binaries directly**: Do no make changes in `src/_binaries/`
   source files
2. **Don't ignore shellcheck warnings**: Address them or explicitly disable with
   explanation
3. **Don't skip tests**: Even for "small" changes, run relevant test suite
4. **Don't modify unrelated files**: Keep changes surgical and focused
5. **Don't remove working tests**: Only modify tests when fixing actual bugs or
   updating functionality

## Additional Resources

- **Bash Tools Framework**: https://fchastanet.github.io/bash-tools-framework/
- **Project Documentation**: https://fchastanet.github.io/bash-tools/
- **BATS Documentation**: https://bats-core.readthedocs.io/
- **ShellCheck Wiki**: https://www.shellcheck.net/wiki/
- **Pre-commit**: https://pre-commit.com/

## Summary

This repository follows a structured approach to Bash development with:

- **Modular design**: Source files compiled into standalone binaries
- **Comprehensive testing**: BATS-based tests on multiple Bash versions
- **Strict quality checks**: Multiple linters and pre-commit hooks
- **Clear conventions**: Naming patterns, file structure, coding standards
- **Docker-based isolation**: Consistent test environments

When working on this codebase, prioritize understanding the existing patterns,
testing thoroughly, and maintaining the high code quality standards established
by the project.
