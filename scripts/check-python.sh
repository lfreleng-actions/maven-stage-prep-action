#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Refuses a Python older than the organisation minimum, so the action
# never runs its POM parser on an end-of-life release.
#
# Usage: bash check-python.sh <version> [<interpreter-path>]
#
# <version> is the one actions/setup-python reports, such as 3.12.3.
# Exits 0 when it is 3.11 or later, and 1 otherwise, with an error
# naming the version and the interpreter.

set -euo pipefail

readonly MIN_MAJOR=3
readonly MIN_MINOR=11

version="${1:-}"
python="${2:-}"
where=""
if [ -n "${python}" ]; then
  where=" at '${python}'"
fi

if [ -z "${version}" ]; then
  echo "ERROR: no Python version given${where}" >&2
  exit 1
fi

if ! [[ "${version}" =~ ^([0-9]+)\.([0-9]+)([.-][0-9A-Za-z.+-]*)?$ ]]; then
  echo "ERROR: unreadable Python version '${version}'${where}" >&2
  exit 1
fi
major=$((10#${BASH_REMATCH[1]}))
minor=$((10#${BASH_REMATCH[2]}))

if (( major < MIN_MAJOR || (major == MIN_MAJOR && minor < MIN_MINOR) )); then
  echo "ERROR: Python ${version}${where} is below the minimum" \
    "${MIN_MAJOR}.${MIN_MINOR}" >&2
  exit 1
fi

echo "Python ${version}${where} ✅"
