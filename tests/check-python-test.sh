#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Tests scripts/check-python.sh on the versions either side of the
# minimum and on input it must not accept.
#
# Usage: bash tests/check-python-test.sh

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
check="${here}/../scripts/check-python.sh"

failures=0

# expect <accept|refuse> <version>
expect() {
  local want="$1" version="$2" got
  if bash "${check}" "${version}" > /dev/null 2>&1; then
    got="accept"
  else
    got="refuse"
  fi
  if [ "${got}" = "${want}" ]; then
    echo "ok: '${version}' (${got})"
  else
    echo "FAIL: '${version}': expected ${want}, got ${got}" >&2
    failures=$((failures + 1))
  fi
}

expect refuse ""
expect refuse "2.7.18"
expect refuse "3.9.25"
expect refuse "3.10"
expect refuse "3.10.19"
expect accept "3.11"
expect accept "3.11.0"
expect accept "3.13.9"
expect accept "3.15.0-alpha.1"
expect accept "4.0.0"
expect refuse "3"
expect refuse "3.x"
expect refuse "pypy3.11"
expect refuse "3.12.3 "

# The refusal must name the interpreter and the minimum
errors="$(mktemp)"
trap 'rm -f -- "${errors}"' EXIT
bash "${check}" "3.10.19" /opt/python/bin/python > /dev/null \
  2> "${errors}" || true
want="Python 3.10.19 at '/opt/python/bin/python' is below the minimum 3.11"
if grep -qF "${want}" "${errors}"; then
  echo "ok: refusal names the interpreter and the minimum"
else
  echo "FAIL: refusal said '$(cat "${errors}")'" >&2
  failures=$((failures + 1))
fi

if [ "${failures}" -ne 0 ]; then
  echo "${failures} case(s) failed" >&2
  exit 1
fi
echo "All check-python cases passed ✅"
