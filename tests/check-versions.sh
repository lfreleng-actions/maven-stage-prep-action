#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Checks the versions maven-stage-prep left in a fixture reactor.
#
# Usage: check-versions.sh <fixture-repo> <expectation>...
#
# An expectation is <pom-path>=<version>: the POM at <pom-path>,
# relative to <fixture-repo>, must declare <version> as its own
# version, or inherit it from its parent when it declares none. Or it
# is <pom-path>@<groupId>:<artifactId>=<version>: that POM's
# dependency on <groupId>:<artifactId> must name <version>. Every
# pom.xml the fixture repository tracks is then checked, named or
# not: none may keep a -SNAPSHOT project or parent version, which a
# staged release would otherwise carry.

set -euo pipefail

dir="${1:?fixture repository}"
shift

status=0
fail() {
  echo "::error::$1"
  status=1
}

# Print the project version a POM declares, or the parent version it
# inherits when it declares none, then the parent version (or empty).
versions() {
  python3 - "$1" <<'PY'
import sys
import xml.etree.ElementTree as ET

project = ET.parse(sys.argv[1]).getroot()
own = project.findtext("{*}version", "").strip()
parent = project.findtext("{*}parent/{*}version", "").strip()
print(own or parent)
print(parent)
PY
}

# Print the version POM "$1" names for its dependency "$2", given as
# groupId:artifactId, or nothing.
dependency_version() {
  python3 - "$1" "$2" <<'PY'
import sys
import xml.etree.ElementTree as ET

group, artifact = sys.argv[2].split(":", 1)
project = ET.parse(sys.argv[1]).getroot()
for dep in project.iterfind("{*}dependencies/{*}dependency"):
    if (dep.findtext("{*}groupId", "").strip() == group
            and dep.findtext("{*}artifactId", "").strip() == artifact):
        print(dep.findtext("{*}version", "").strip())
        break
PY
}

for expectation in "$@"; do
  target="${expectation%%=*}"
  want="${expectation#*=}"
  pom="${dir}/${target%%@*}"
  if [ ! -f "${pom}" ]; then
    fail "${pom}: missing"
    continue
  fi
  case "${target}" in
    *@*)
      label="${pom} dependency ${target#*@}"
      got="$(dependency_version "${pom}" "${target#*@}")" ;;
    *)
      label="${pom}"
      got="$(versions "${pom}" | sed -n 1p)" ;;
  esac
  if [ "${got}" = "${want}" ]; then
    echo "${label}: ${got} ✅"
  else
    fail "${label}: version '${got}', expected '${want}'"
  fi
done

while IFS= read -r -d '' path; do
  pom="${dir}/${path}"
  while IFS= read -r version; do
    case "${version}" in
      *-SNAPSHOT) fail "${pom}: still declares ${version}" ;;
    esac
  done < <(versions "${pom}" | sort -u)
done < <(git -C "${dir}" ls-files -z -- 'pom.xml' '*/pom.xml')

exit "${status}"
