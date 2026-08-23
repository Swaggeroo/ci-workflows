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
    uses: Swaggeroo/ci-workflows/.github/workflows/release-and-build.yaml@v1
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
| `dockerhub_enabled` | Whether to push to Docker Hub | No | `false` |
| `dockerhub_username` | Docker Hub username / org | No | `""` |

#### Secrets

| Secret | Description | Required |
|---|---|---|
| `token` | GitHub token for checkout and creating release tags | Yes |
| `registry_password` | Password/token for GHCR login | Yes |
| `dockerhub_password` | Password/token for Docker Hub login | No |

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
    uses: Swaggeroo/ci-workflows/.github/workflows/pr-bump-version.yaml@v1
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

## Renovate Configuration

Renovate automatically detects and updates reusable workflow references in your caller repositories.

To keep your workflow calls updated to the latest tag (e.g. `@v1`), no special config is needed. If you pin SHA digests with comments, Renovate can maintain them with:

```json
{
  "extends": [
    "config:recommended",
    ":pinGitHubActionDigests"
  ]
}
```
