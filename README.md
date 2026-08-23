# ci-workflows

Centralized reusable GitHub Actions workflows for Go / Docker services.

## Available Workflows

### 1. Release and Build (`.github/workflows/release-and-build.yaml`)

Creates GitHub releases, builds multi-arch Docker images (linux/amd64 and linux/arm64) using Buildx, and pushes manifests to GHCR (and optionally Docker Hub).

#### Usage

```yaml
jobs:
  release-and-build:
    permissions:
      contents: write
      packages: write
    uses: Swaggeroo/ci-workflows/.github/workflows/release-and-build.yaml@v1.0.0
    with:
      version_file: version.txt
      image_namespace: ${{ github.repository_owner }}
      image_name: ${{ github.event.repository.name }}
      publish_release: true
    secrets:
      token: ${{ secrets.GITHUB_TOKEN }}
      registry_password: ${{ secrets.GITHUB_TOKEN }}
```

#### Inputs

| Input | Description | Required | Default |
|---|---|---|---|
| `version_file` | Path to the version file | No | `version.txt` |
| `image_namespace` | Registry namespace or owner | Yes | - |
| `image_name` | Registry image name | Yes | - |
| `publish_release` | Whether to create GitHub release and tag | No | `true` |
| `dockerhub_enabled` | Whether to also push to Docker Hub | No | `false` |
| `dockerhub_username` | Docker Hub username or organization | No | `""` |

#### Secrets

| Secret | Description | Required |
|---|---|---|
| `token` | GitHub token for checkout and creating release tags | Yes |
| `registry_password` | Password or token for GHCR login | Yes |
| `dockerhub_password` | Password or token for Docker Hub login | No |

---

### 2. Renovate PR Version Bump (`.github/workflows/pr-bump-version.yaml`)

Automatically increments the patch version in `version.txt` (and runs `./scripts/version-sync.sh bump` if present) for Renovate bot pushes.

#### Usage

```yaml
jobs:
  bump-version:
    if: github.actor == 'renovate[bot]'
    permissions:
      contents: write
    uses: Swaggeroo/ci-workflows/.github/workflows/pr-bump-version.yaml@v1.0.0
    with:
      version_file: version.txt
    secrets:
      token: ${{ secrets.GITHUB_TOKEN }}
```

#### Inputs

| Input | Description | Required | Default |
|---|---|---|---|
| `version_file` | Path to the semantic version file | No | `version.txt` |

#### Secrets

| Secret | Description | Required |
|---|---|---|
| `token` | GitHub token for checkout, commit, and push | Yes |

---

## Releasing New Versions

This repository uses **Semantic Versioning** (`vMAJOR.MINOR.PATCH`):
- **MAJOR** (`v2.0.0`): Breaking changes (removed/renamed required inputs or secrets, incompatible behavior changes).
- **MINOR** (`v1.1.0`): New features or optional inputs that are backward-compatible.
- **PATCH** (`v1.0.1`): Bug fixes or optimizations without changing the interface.

### Step-by-Step Release Process

1. **Commit and push changes to `main`**:
   ```bash
   git add .
   git commit -m "feat: add support for custom build args"
   git push origin main
   ```

2. **Create an annotated Git tag**:
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0: Add support for custom build args"
   ```

3. **Push the tag to GitHub**:
   ```bash
   git push origin v1.1.0
   ```

4. **(Optional) Create a GitHub Release**:
   Using the GitHub CLI:
   ```bash
   gh release create v1.1.0 --generate-notes
   ```
   Or via the GitHub web UI under **Releases** -> **Draft a new release** -> select tag `v1.1.0`.

---

## Renovate Configuration

Renovate automatically detects and updates reusable workflow references in your caller repositories.

When you push a new semver tag (e.g. `v1.1.0`), Renovate will automatically open pull requests in repositories using these workflows to bump the version tag.

If you pin SHA digests with comments in caller repos, Renovate will maintain both the SHA and the version comment automatically when configured with:

```json
{
  "extends": [
    "config:recommended",
    ":pinGitHubActionDigests"
  ]
}
```
