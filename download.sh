#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Basis Network
# SPDX-License-Identifier: Apache-2.0
# ---------------------------------------------------------------------------
# Downloads the Basis CLI and verifies it against the checksum kept IN THIS
# REPOSITORY.
#
#     ./download.sh                    linux-x86_64 (default)
#     ./download.sh windows-x86_64
#     BASIS_CLI_VERSION=v0.1.0 ./download.sh
#
# The verification is the whole point of this repository. The binary comes from
# a GitHub release; the checksum comes from git, where it has a commit, an
# author and a diff anybody can read. Checking one against the other is what
# makes keeping them apart safe. The checksum is NEVER downloaded -- doing so
# would turn the check into a mirror of whatever the release happens to serve.
#
# If the verification fails, DO NOT run what you downloaded.
# ---------------------------------------------------------------------------
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO="${BASIS_CLI_REPO:-basis-network/basis-cli}"
BASE_URL="${BASIS_CLI_BASE_URL:-https://github.com/$REPO/releases/download}"
PLATFORM="${1:-linux-x86_64}"

# Globs rather than `ls`: the output of `ls` is for people to read, not for a
# script to take apart.
versions() {
  local d
  for d in "$here"/checksums/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
}

platforms() {
  local f
  for f in "$here/checksums/$1"/*.sha256; do
    [ -f "$f" ] || continue
    basename "$f" .sha256
  done
}

# Newest version this repository knows about, unless you ask for another one.
newest() {
  local v newest=""
  while read -r v; do
    [ -n "$v" ] || continue
    if [ -z "$newest" ] || \
       [ "$(printf '%s\n%s\n' "$newest" "$v" | sort -V | tail -n 1)" = "$v" ]; then
      newest="$v"
    fi
  done < <(versions)
  printf '%s' "$newest"
}

VERSION="${BASIS_CLI_VERSION:-$(newest)}"

sums="$here/checksums/$VERSION/$PLATFORM.sha256"
[ -f "$sums" ] || {
  echo "  x no checksum file for $VERSION/$PLATFORM" >&2
  echo "    versions:  $(versions | tr '\n' ' ')" >&2
  echo "    platforms: $(platforms "$VERSION" | tr '\n' ' ')" >&2
  exit 1
}

# macOS ships `shasum`, not `sha256sum`. Both read the same file format.
if command -v sha256sum >/dev/null 2>&1; then
  check() { sha256sum -c "$1"; }
elif command -v shasum >/dev/null 2>&1; then
  check() { shasum -a 256 -c "$1"; }
else
  echo "  x neither sha256sum nor shasum found -- cannot verify, refusing to continue" >&2
  exit 1
fi

dest="$here/bin/$PLATFORM"
mkdir -p "$dest"

echo "==> downloading $VERSION for $PLATFORM"
while read -r _ name; do
  [ -n "$name" ] || continue
  # Release assets live in one flat namespace, so they carry the platform in
  # their name: `basis` is published as `basis-linux-x86_64`, and `basis.exe`
  # as `basis-windows-x86_64.exe`. They are saved back under the bare name,
  # which is what the checksum file lists.
  stem="${name%.*}"
  ext=""; [ "$stem" != "$name" ] && ext=".${name##*.}"
  asset="$stem-$PLATFORM$ext"

  echo "    $asset -> $name"
  curl -fSL --retry 3 --retry-delay 2 -o "$dest/$name" "$BASE_URL/$VERSION/$asset"
done < "$sums"

echo "==> verifying against checksums/$VERSION/$PLATFORM.sha256"
# Read from the repository and only *copied* next to the binary, because the
# format carries bare file names and `-c` resolves them from the cwd.
cp "$sums" "$dest/.sha256.check"
( cd "$dest" && check .sha256.check )
rm -f "$dest/.sha256.check"

chmod +x "$dest"/basis 2>/dev/null || true
echo "  ok  $dest"
echo
echo "Try it:  $dest/basis --help"
