#!/usr/bin/env bash
# Fetch all submodules, resolving their relative URLs against the upstream
# owner (darlinghq) even when this is a fork. Shared by the DEB and RPM jobs.
set -euo pipefail

# .gitmodules uses relative URLs (../darling-*.git), which git resolves against
# the origin remote. On a fork that points at the fork owner, where those
# submodule repos do not exist. The submodules live under darlinghq, so rewrite
# the owner before fetching (this covers nested submodules too).
owner=$(git remote get-url origin | sed -E 's#^([a-z]+://)?([^@/]+@)?github\.com[:/]##; s#/.*##; s#\.git$##')
if [ -n "$owner" ] && [ "$owner" != "darlinghq" ]; then
    git config --global "url.https://github.com/darlinghq/."insteadOf "https://github.com/${owner}/"
fi

# actions/checkout fetches submodules one at a time; do it in parallel.
git submodule update --init --recursive --depth 1 --jobs 8
