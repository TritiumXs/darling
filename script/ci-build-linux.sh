#!/usr/bin/env bash
# Build and package by reusing the repository's own tools/debian/make-deb —
# the exact script the existing CI (actions.yaml) uses. That single build
# produces both the .debs and, via its cmake build tree, the raw installed
# output tree. Requires: ARCH (amd64|arm64).
set -euo pipefail

ARCH="${ARCH:?ARCH is required}"

echo "::group::Build DEB packages (tools/debian/make-deb)"
mkdir -p dist
ccache --zero-stats || true
# make-deb drives debian/rules, which configures cmake with the per-arch
# defaults: on amd64 TARGET_i386 + TARGET_x86_64 are on (a fat tree carrying
# both the x86 and amd64 slices); on arm64 TARGET_ARM64 is on.
./tools/debian/make-deb
mv ../*.deb dist/
echo "::endgroup::"

echo "::group::Copy out build output"
# make-deb builds in debbuild/ (see debian/rules --builddirectory). Reuse that
# already-compiled tree so the raw output needs no second compile.
if [ -f debbuild/cmake_install.cmake ]; then
    mkdir -p stage
    DESTDIR="$PWD/stage" cmake --install debbuild
    tar -cJf "dist/darling-output-${ARCH}.tar.xz" -C stage .
else
    echo "::warning::debbuild tree not found; skipping raw output tarball"
fi
echo "::endgroup::"

ccache --show-stats --verbose || true
ls -l dist
