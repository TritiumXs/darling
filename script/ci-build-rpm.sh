#!/usr/bin/env bash
# Build RPMs by reusing the repository's own rpm/ build directory:
#   * rpm/Dockerfile  - base image that installs RPM Fusion and bootstraps all
#                       BuildRequires with yum-builddep from the spec
#   * rpm/build.bsh   - the actual rpmbuild driver
# Set RPM_OS to override the Dockerfile's base image (default: fedora:37).
set -euo pipefail

raw="${RUNNER_TEMP}/rpm-raw"
dist="${RUNNER_TEMP}/rpms"
mkdir -p "$raw" "$dist"

echo "::group::Build RPM builder image (rpm/Dockerfile)"
build_args=()
[ -n "${RPM_OS:-}" ] && build_args+=(--build-arg "OS=${RPM_OS}")
docker build "${build_args[@]}" -f rpm/Dockerfile -t darling-rpm-build rpm/
echo "::endgroup::"

echo "::group::Build RPMs (rpm/build.bsh)"
# The Dockerfile CMD is `bash -xv /src/rpm/build.bsh`. build.bsh calls sudo,
# which the base image may not ship, so install it only when missing and then
# run the repository script unchanged.
docker run --rm \
    -v "${GITHUB_WORKSPACE}:/src:ro" \
    -v "${raw}:/root/rpmbuild/RPMS" \
    darling-rpm-build \
    bash -euxvc 'git config --global --add safe.directory /src; command -v sudo >/dev/null 2>&1 || dnf install -y sudo; bash -xv /src/rpm/build.bsh'
echo "::endgroup::"

echo "::group::Collect RPMs"
# docker-compose.yml mounts RPMS at /root/rpmbuild/RPMS/<arch>; flatten the
# resulting .rpm files into a single artifact directory.
find "$raw" -name '*.rpm' -type f -exec cp {} "$dist/" \; 2>/dev/null || true
ls -l "$dist"
echo "::endgroup::"
