#!/bin/sh
set -euo pipefail

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
PACKAGE_FILE="$REPO_ROOT/Lesaria.swiftpm/Package.swift"
PROJECT_FILE="$REPO_ROOT/project.yml"
BUILD_NUMBER="${CI_BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-1}}"

if [ -f "$PACKAGE_FILE" ]; then
  perl -0pi -e 's/bundleVersion: "[^"]+"/bundleVersion: "'"$BUILD_NUMBER"'"/' "$PACKAGE_FILE"
fi

if [ -f "$PROJECT_FILE" ]; then
  perl -0pi -e 's/CURRENT_PROJECT_VERSION: "[^"]+"/CURRENT_PROJECT_VERSION: "'"$BUILD_NUMBER"'"/' "$PROJECT_FILE"
fi
