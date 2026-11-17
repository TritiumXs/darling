#!/usr/bin/env bash
# Common setup for the Linux build jobs: submodules, packages and ccache.
set -euo pipefail

echo "::group::Checkout submodules"
bash "$(dirname "$0")/ci-checkout-submodules.sh"
echo "::endgroup::"

echo "::group::Install build dependencies"
sudo apt-get update
sudo apt-get install -y devscripts equivs debhelper ccache ninja-build clang
sudo mk-build-deps -i -r -t "apt-get --no-install-recommends -y" debian/control
echo "::endgroup::"

echo "::group::Free up disk space"
sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/share/boost
echo "::endgroup::"

echo "::group::Configure ccache"
# debuild scrubs the environment, so configure ccache system-wide. The mtime
# sloppiness settings matter with a fresh CI checkout.
sudo tee /etc/ccache.conf > /dev/null <<EOF
cache_dir = ${HOME}/.ccache
max_size = 5G
compiler_check = content
sloppiness = time_macros,include_file_mtime,include_file_ctime
EOF
echo "::endgroup::"
