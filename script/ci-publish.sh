#!/usr/bin/env bash
# Publish downloaded artifacts into the target GitHub Release.
# Requires: CHANNEL, RELEASE_TAG, RELEASE_NAME, PRERELEASE, VERSION, and a
# GH_TOKEN with contents: write. Downloads must be merged into ./release-assets.
set -euo pipefail

CHANNEL="${CHANNEL:?CHANNEL is required}"
RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG is required}"
RELEASE_NAME="${RELEASE_NAME:?RELEASE_NAME is required}"
PRERELEASE="${PRERELEASE:?PRERELEASE is required}"
VERSION="${VERSION:-unknown}"

echo "::group::Prefix assets with channel"
mkdir -p final
for f in release-assets/*; do
    [ -f "$f" ] || continue
    mv "$f" "final/${CHANNEL}-$(basename "$f")"
done
ls -l final
echo "::endgroup::"

{
    echo "Darling ${CHANNEL} build - ${VERSION}"
    echo
    echo "Commit: ${GITHUB_SHA:-unknown}"
    echo "Built:  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "Assets are prefixed with \`${CHANNEL}-\`."
    echo
    echo "- \`tar.xz\`: installed output tree (the amd64 tree also carries the x86/i386 slices)."
    echo "- \`.deb\`: split Debian packages built with \`tools/debian/make-deb\`."
    echo "- \`.rpm\`: RPM packages built with \`rpm/build.bsh\` (best effort)."
} > release-notes.md

if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
    # Rolling Release shared by CI and Nightly: drop only this channel's
    # previous assets, then upload the fresh set.
    for asset in $(gh release view "$RELEASE_TAG" --json assets \
                     --jq '.assets[].name'); do
        case "$asset" in
            "${CHANNEL}-"*) gh release delete-asset -y "$RELEASE_TAG" "$asset" ;;
        esac
    done
    gh release upload "$RELEASE_TAG" final/* --clobber
    gh release edit "$RELEASE_TAG" --notes-file release-notes.md
else
    args=(--title "$RELEASE_NAME" --notes-file release-notes.md)
    [ "$PRERELEASE" = "true" ] && args+=(--prerelease)
    gh release create "$RELEASE_TAG" final/* "${args[@]}"
fi
