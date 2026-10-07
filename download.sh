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
# If the verification fails, or the run is cut short, nothing it downloaded is
# put where the binary goes, and whatever was in `bin/<platform>/` is left as
# it was.
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

# Older macOS ships `shasum` and no `sha256sum`; newer versions have both. They
# read the same file format.
if command -v sha256sum >/dev/null 2>&1; then
  check() { sha256sum -c "$1"; }
elif command -v shasum >/dev/null 2>&1; then
  check() { shasum -a 256 -c "$1"; }
else
  echo "  x neither sha256sum nor shasum found -- cannot verify, refusing to continue" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "  x curl not found -- cannot download, refusing to continue" >&2
  exit 1
fi

dest="$here/bin/$PLATFORM"

# Everything is fetched and checked in a staging directory inside `dest`, and
# moved out of it only once all of it has passed. Fetching straight into `dest`
# would overwrite a binary verified on an earlier run before the new one had
# been checked -- and an overwritten file keeps its mode, so a download that
# failed, or broke off half-way, would be left in its place, executable, under
# the name people run. Inside `dest`, wherever it really lives, so that the
# final move is a rename within one directory and never a copy across
# filesystems that could stop half-way.
mkdir -p "$dest"
stage="$(mktemp -d "$dest/.stage.XXXXXX")"
# A function rather than a string: bashcov charges a trap string to whichever
# line the script happens to exit on, and those lines would count as covered.
# `|| true` so that a cleanup that fails cannot change the run's exit status.
unstage() { rm -rf "$stage" || true; }
trap unstage EXIT

echo "==> downloading $VERSION for $PLATFORM"
listed=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  # `sha256sum -c` only warns about a line it cannot parse, and still exits 0
  # when another line checks out -- so a malformed entry would be fetched and
  # never verified. Each line has to be exactly `<64 hex digits>  <name>`, the
  # name a plain file name, before anything is fetched for it.
  sum="${line%%  *}"
  name="${line#*  }"
  case "$sum" in (*[!0-9a-f]*) sum="" ;; esac
  case "$name" in (.*|*/*) name="" ;; esac
  if [ "${#sum}" -ne 64 ] || [ -z "$name" ] || [ "$line" != "$sum  $name" ]; then
    echo "  x checksums/$VERSION/$PLATFORM.sha256 has a line that is not" \
      "'<sha256>  <name>' -- cannot verify, refusing to continue" >&2
    exit 1
  fi
  listed=$((listed + 1))

  # Release assets live in one flat namespace, so they carry the platform in
  # their name: `basis` is published as `basis-linux-x86_64`, and `basis.exe`
  # as `basis-windows-x86_64.exe`. They are saved back under the bare name,
  # which is what the checksum file lists.
  stem="${name%.*}"
  ext=""; [ "$stem" != "$name" ] && ext=".${name##*.}"
  asset="$stem-$PLATFORM$ext"

  echo "    $asset -> $name"
  curl -fSL --retry 3 --retry-delay 2 -o "$stage/$name" "$BASE_URL/$VERSION/$asset"
done < "$sums"

[ "$listed" -gt 0 ] || {
  echo "  x checksums/$VERSION/$PLATFORM.sha256 lists nothing -- refusing to continue" >&2
  exit 1
}

echo "==> verifying against checksums/$VERSION/$PLATFORM.sha256"
# Read from the repository and only *copied* next to the binary, because the
# format carries bare file names and `-c` resolves them from the cwd.
cp "$sums" "$stage/.sha256.check"
# `|| exit` rather than trusting `set -e`: a bash 3.2 built from GNU sources
# carries on after a ( subshell ) fails, and this is the line that must stop.
( cd "$stage" && check .sha256.check ) || exit $?
rm -f "$stage/.sha256.check"

chmod +x "$stage"/basis 2>/dev/null || true
mv -f "$stage"/* "$dest"/
echo "  ok  $dest"
echo
echo "Try it:  $dest/basis --help"
