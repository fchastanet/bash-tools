# Pre-Build Action Integration for Reusable Workflow

## Date: 2026-02-25

## Problem

The bash-tools repository needs to execute custom setup steps (Docker configuration, vendor installation, documentation
checks) after checking out the content repository but before building the Hugo site. The reusable workflow
`fchastanet/my-documents/.github/workflows/build-site-action.yml@master` currently doesn't support injection of custom
pre-build steps.

## Solution

Implement a composite action pattern that allows calling repositories to specify custom pre-build actions.

## Implementation

### 1. Composite Action in bash-tools (COMPLETED)

Created `.github/actions/pre-build/action.yml` in bash-tools repository with the required setup steps.

### 2. Modifications to Reusable Workflow

In the `fchastanet/my-documents` repository, modify `.github/workflows/build-site-action.yml`:

#### Add new input parameter:

```yaml
on:
  workflow_call:
    inputs:
      site-name:
        description: 'Name of the site to build (used for config file lookup)'
        required: true
        type: string
      site-dir:
        description: 'Directory containing the site content (default: .)'
        required: false
        type: string
        default: '.'
      checkout-repo:
        description: 'Repository to checkout content from (owner/repo format, if different from caller)'
        required: false
        type: string
        default: ''
      checkout-ref:
        description: 'Git reference to checkout (branch, tag, or commit SHA)'
        required: false
        type: string
        default: 'master'
      pre-build-action: # NEW INPUT
        description: 'Optional path to a composite action to run after content checkout (format: owner/repo/path@ref)'
        required: false
        type: string
        default: ''
```

#### Add pre-build step in build job:

Insert this step **after** the "Checkout content" step and **before** the "Setup Go" step:

```yaml
- name: Run pre-build action for ${{ inputs.site-name }}
  if: inputs.pre-build-action != ''
  uses: ${{ inputs.pre-build-action }}
```

#### Complete modified section:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout orchestrator (my-documents)
        uses: actions/checkout@v6
        with:
          repository: fchastanet/my-documents
          fetch-depth: 0

      - name: Checkout content (${{ inputs.site-name }})
        if: inputs.checkout-repo != ''
        uses: actions/checkout@v6
        with:
          repository: ${{ inputs.checkout-repo }}
          path: _site-content
          ref: ${{ inputs.checkout-ref }}
          fetch-depth: 0

      # ====== NEW STEP ======
      - name: Run pre-build action for ${{ inputs.site-name }}
        if: inputs.pre-build-action != ''
        working-directory: _site-content
        uses: ${{ inputs.pre-build-action }}
      # ======================

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      # ... rest of the steps
```

**Important:** Add `working-directory: _site-content` to ensure the composite action runs in the correct context.

### 3. Update bash-tools workflow

In `bash-tools/.github/workflows/build-site.yml`, add the new input:

```yaml
jobs:
  build-deploy:
    uses: fchastanet/my-documents/.github/workflows/build-site-action.yml@master
    with:
      site-name: 'bash-tools'
      baseURL: 'https://fchastanet.github.io/bash-tools'
      checkout-repo: 'fchastanet/bash-tools'
      pre-build-action: 'fchastanet/bash-tools/.github/actions/pre-build@master' # NEW
    permissions:
      contents: read
      pages: write
      id-token: write
```

## Benefits

1. **Native GitHub Actions Support**: Can use `docker/setup-buildx-action` and other actions directly
2. **Better Visibility**: Each step in the composite action shows separately in the workflow UI
3. **Reusability**: The pattern can be used by other sites that need custom pre-build steps
4. **Version Control**: The composite action is versioned alongside the content
5. **Type Safety**: Composite actions support typed inputs/outputs
6. **Maintainability**: Clear separation of concerns between orchestrator and content-specific logic

## Testing

After implementing these changes:

1. Push the composite action to bash-tools repository
2. Update the reusable workflow in my-documents repository
3. Update bash-tools workflow to use the new `pre-build-action` input
4. Trigger the workflow and verify:
   - Docker Buildx is set up
   - Docker image is pulled
   - Vendors are installed
   - Documentation check passes
   - Hugo build completes successfully

## Alternative Approach Considered

**Shell script hook**: A simpler approach using a shell script that would be called if present. This was rejected
because it doesn't support native GitHub Actions and has limited visibility in the workflow UI.

## Future Enhancements

Consider adding:

- `post-build-action`: For cleanup or post-processing tasks
- Input validation in the reusable workflow
- Caching strategies for Docker images and vendor dependencies
- Support for multiple pre-build actions (as an array)
