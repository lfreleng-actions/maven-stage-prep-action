<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
-->

# 📦 Maven Stage Prep Action

Composite GitHub Action to prepare a Maven project for staging release.
This is the GitHub Actions replacement for JJB's `maven-patch-release.sh` and
`lf-maven-versions-plugin` scripts.

## Description

This action automates the release preparation workflow for Maven projects
managed via Gerrit. It removes `-SNAPSHOT` suffixes from POM versions,
creates git format-patch and bundle artifacts, and records the commit hash
for downstream tagging.

## Features

- Remove `-SNAPSHOT` from POM versions using **sed** (default) or the
  **Maven versions-plugin**
- Create `git format-patch` for the release commit
- Create `git bundle` for the release commit
- Record commit SHA in `taglist.log` for downstream tagging
- Output the release version string for downstream jobs
- Generate GitHub Step Summary with release details

## Usage

### Basic Example (sed method)

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

- name: Maven stage prep
  id: stage-prep
  uses: askb/maven-stage-prep-action@main
  with:
    project-name: 'my-project'
    gerrit-branch: 'master'

- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    name: staging-artifacts
    path: |
      ${{ steps.stage-prep.outputs.patch-path }}
      ${{ steps.stage-prep.outputs.bundle-path }}
      ${{ steps.stage-prep.outputs.taglist-path }}
```

### Versions-Plugin Method

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

- name: Maven stage prep
  id: stage-prep
  uses: askb/maven-stage-prep-action@main
  with:
    project-name: 'my-project'
    gerrit-branch: 'master'
    version-method: 'versions-plugin'
    java-version: '21'
    mvn-version: '3.9.11'
```

### With Version Override

```yaml
- name: Maven stage prep
  id: stage-prep
  uses: askb/maven-stage-prep-action@main
  with:
    project-name: 'my-project'
    gerrit-branch: 'master'
    version-method: 'versions-plugin'
    version-override: '2.0.0'
```

## Inputs

<!-- markdownlint-disable line-length -->

| Input              | Description                                           | Required | Default   |
| ------------------ | ----------------------------------------------------- | -------- | --------- |
| `pom-file`         | Path to root POM file                                 | No       | `pom.xml` |
| `version-method`   | Method to remove SNAPSHOT: `sed` or `versions-plugin` | No       | `sed`     |
| `version-override` | Explicit version for versions-plugin `newVersion`     | No       | `""`      |
| `project-name`     | Project name for patch/bundle file naming             | **Yes**  | —         |
| `gerrit-branch`    | Branch name for `git format-patch` base ref           | **Yes**  | —         |
| `java-version`     | OpenJDK version (versions-plugin method)              | No       | `21`      |
| `mvn-version`      | Maven version (versions-plugin method)                | No       | `3.9.11`  |

<!-- markdownlint-enable line-length -->

## Outputs

| Output            | Description                           |
| ----------------- | ------------------------------------- |
| `release-version` | De-SNAPSHOTted release version string |
| `patch-path`      | Path to git format-patch file         |
| `bundle-path`     | Path to git bundle file               |
| `taglist-path`    | Path to `taglist.log` file            |

## How It Works

1. **Record commit hash** — writes `<project> <SHA>` to
   `archives/patches/taglist.log`
2. **Remove SNAPSHOT** — strips `-SNAPSHOT` from all POM `<version>` tags
   using sed, or uses the Maven versions-plugin for precise version updates
3. **Extract release version** — reads the de-SNAPSHOTted version from the
   root POM
4. **Git commit** — commits all POM changes as
   `Release <project> <version>`
5. **Create patch** — runs `git format-patch` against the Gerrit branch
6. **Create bundle** — runs `git bundle create` for the release commits

## Comparison with JJB

This action replaces the following JJB scripts:

| JJB Script                  | Action Method                         |
| --------------------------- | ------------------------------------- |
| `maven-patch-release.sh`    | `version-method: sed`                 |
| `lf-maven-versions-plugin`  | `version-method: versions-plugin`     |

The JJB `maven-patch-release.sh` script:

```bash
PATCH_DIR="$WORKSPACE/archives/patches"
mkdir -p "$PATCH_DIR"
echo "$PROJECT" "$(git rev-parse --verify HEAD)" | tee -a "$PATCH_DIR/taglist.log"
find . -name "*.xml" -print0 | xargs -0 sed -i 's/-SNAPSHOT//g'
git commit -am "Release $PROJECT"
git format-patch --stdout "origin/$GERRIT_BRANCH" > "$PATCH_DIR/${PROJECT//\//-}.patch"
git bundle create "$PATCH_DIR/${PROJECT//\//-}.bundle" "origin/${GERRIT_BRANCH}..HEAD"
```

## License

[Apache-2.0](LICENSES/Apache-2.0.txt)
