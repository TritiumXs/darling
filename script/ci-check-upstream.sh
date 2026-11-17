#!/usr/bin/env bash
# Decide whether a release build is needed and which upstream version to build.
# The version always comes from darlinghq/darling releases:
#   - INPUT_TAG, when set, must be a tag of a published upstream release
#   - otherwise the latest upstream release tag is used
# Writes `tag` and `new` to GITHUB_OUTPUT. FORCE=true (manual dispatch)
# rebuilds the version even if this repository already published it.
set -euo pipefail

if [ -n "${INPUT_TAG:-}" ]; then
    tag="$INPUT_TAG"
    # A manually supplied tag must be a real upstream release, so a build is
    # always tied to a version published by the upstream project.
    if ! gh api "repos/darlinghq/darling/releases/tags/${tag}" >/dev/null 2>&1; then
        echo "::error::${tag} is not a published release of darlinghq/darling"
        echo "tag=${tag}" >> "$GITHUB_OUTPUT"
        echo "new=false" >> "$GITHUB_OUTPUT"
        exit 0
    fi
else
    tag=$(gh api repos/darlinghq/darling/releases/latest --jq .tag_name)
fi

echo "Upstream release tag: ${tag}"
echo "tag=${tag}" >> "$GITHUB_OUTPUT"

if [ -z "$tag" ]; then
    echo "No upstream tag available; skipping."
    echo "new=false" >> "$GITHUB_OUTPUT"
elif [ "${FORCE:-false}" = "true" ]; then
    echo "Manual trigger; rebuilding upstream release ${tag}."
    echo "new=true" >> "$GITHUB_OUTPUT"
elif gh release view "stable-${tag}" >/dev/null 2>&1; then
    echo "stable-${tag} already exists; nothing to do."
    echo "new=false" >> "$GITHUB_OUTPUT"
else
    echo "New upstream release detected; building stable-${tag}."
    echo "new=true" >> "$GITHUB_OUTPUT"
fi
