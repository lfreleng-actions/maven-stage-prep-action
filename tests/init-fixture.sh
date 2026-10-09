#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Turns the current directory into a git repository holding a fixture
# reactor, as a project checkout would be when the action runs: the
# action works in the workspace root, commits there, and diffs against
# origin/<gerrit-branch>.
#
# Usage: init-fixture.sh <fixture-dir> [<excluded-path>...]
#
# Each <excluded-path>, such as the action's own checkout, is kept out
# of the repository.

set -euo pipefail

fixture="${1:?fixture directory}"
shift

cp -R -- "${fixture}/." .
git init -q -b main
for excluded in "$@"; do
  printf '/%s/\n' "${excluded}" >> .git/info/exclude
done
git config user.email 'ci-test@example.org'
git config user.name 'CI Test'
git config commit.gpgsign false
git add -A
git commit -q -m 'Add fixture'
git update-ref refs/remotes/origin/main HEAD
echo "Fixture ${fixture} committed:"
git ls-files
