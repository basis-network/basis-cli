#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Basis Network
# SPDX-License-Identifier: Apache-2.0
# ---------------------------------------------------------------------------
# The test suite for `download.sh`.
#
#     make check            or            test/run.sh
#
# It needs nothing that is not already needed to run `download.sh` itself:
# bash, curl and sha256sum (or shasum). No test framework, no network.
#
# Each case builds a throwaway world under a temporary directory: a copy of
# `download.sh`, a `checksums/` tree written by hand, and a "release server"
# that is just a directory reached over `file://` through `BASIS_CLI_BASE_URL`.
# Nothing binary is committed -- the fixtures are made here, at run time, from
# strings.
#
# What is worth testing is what the script promises: that a download which does
# not match the checksum kept in this repository does not reach the user. Most
# of the cases below are failure paths -- a tampered download, a failed
# upgrade, a malformed checksum line, a machine without a hash tool or without
# curl -- and they are the reason this file exists.
# ---------------------------------------------------------------------------
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/../download.sh"

passed=0
failed=0

# --------------------------------------------------------------------------
# The world each case runs in.
# --------------------------------------------------------------------------

# Same fallback as the script under test: older macOS ships `shasum` and no
# `sha256sum`. If neither is here the suite cannot check anything.
if command -v sha256sum >/dev/null 2>&1; then
  sum() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sum() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
  echo "x neither sha256sum nor shasum found -- cannot run the suite" >&2
  exit 1
fi

# A fresh copy of the script plus the empty shape around it. `download.sh`
# resolves `checksums/` from its own directory, so the copy has to sit at the
# root of the fabricated tree and not be symlinked into it.
sandbox() {
  work="$(mktemp -d)"
  mkdir -p "$work/repo" "$work/releases"
  cp "$script" "$work/repo/download.sh"
  printf '%s' "$work"
}

# Publishes one asset: writes the file the release serves, under the name a
# release actually uses, and records in `checksums/` the *bare* name the user
# ends up with. `recorded` is what goes in the checksum file, which is how a
# tampered download is simulated -- record one thing, serve another.
publish() {
  local work="$1" version="$2" platform="$3" name="$4" content="$5" recorded="${6:-}"
  local stem="${name%.*}" ext=""
  [ "$stem" != "$name" ] && ext=".${name##*.}"

  mkdir -p "$work/releases/$version" "$work/repo/checksums/$version"
  printf '%s' "$content" > "$work/releases/$version/$stem-$platform$ext"

  local digest
  if [ -n "$recorded" ]; then
    printf '%s' "$recorded" > "$work/tampered"
    digest="$(sum "$work/tampered")"
  else
    digest="$(sum "$work/releases/$version/$stem-$platform$ext")"
  fi
  printf '%s  %s\n' "$digest" "$name" \
    >> "$work/repo/checksums/$version/$platform.sha256"
}

# Runs the script in its sandbox and leaves the combined output in `$out` and
# the exit status in `$status`, so a case can assert on both.
download() {
  local work="$1"; shift
  out="$(cd "$work/repo" && BASIS_CLI_BASE_URL="file://$work/releases" \
    ./download.sh "$@" 2>&1)"
  status=$?
}

# --------------------------------------------------------------------------
# Assertions. Each prints one line, and the line says what was expected.
# --------------------------------------------------------------------------

check() {
  local what="$1" condition="$2"
  if [ "$condition" = yes ]; then
    printf '  ok    %s\n' "$what"
    passed=$((passed + 1))
  else
    printf '  FAIL  %s\n' "$what"
    [ -n "${out:-}" ] && printf '%s\n' "$out" | sed 's/^/          | /'
    failed=$((failed + 1))
  fi
}

equal() { local w="$1" a="$2" b="$3"; check "$w" "$([ "$a" = "$b" ] && echo yes || echo no)"; }
exists() { local w="$1" f="$2"; check "$w" "$([ -f "$f" ] && echo yes || echo no)"; }
absent() { local w="$1" f="$2"; check "$w" "$([ ! -e "$f" ] && echo yes || echo no)"; }
# Both patterns open with `(`, which bash always allows and here needs: the
# bash 3.2 that macOS ships ends a command substitution at the first `)` it
# sees, so without them every call below is a syntax error on a stock Mac.
mentions() { local w="$1" t="$2"; check "$w" "$(case "${out:-}" in (*"$t"*) echo yes ;; (*) echo no ;; esac)"; }

# The hidden entries in a directory, one per line, and nothing if there are
# none. A run that stops half-way leaves its traces here, where `ls` would not
# show them.
hidden() { local f; for f in "$1"/.[!.]*; do [ ! -e "$f" ] || printf '%s\n' "${f##*/}"; done; }

case_() { printf '\n%s\n' "$1"; }

# Each case throws its sandbox away as it ends. Measuring coverage needs them
# to survive instead: the copy of `download.sh` inside the sandbox is the file
# that carries the execution trace, and a file that no longer exists cannot be
# attributed. See `test/coverage.sh`.
cleanup() { [ -n "${BASIS_TEST_KEEP:-}" ] || rm -rf "$1"; }

# --------------------------------------------------------------------------

case_ 'a matching download is verified and left in place'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the linux binary'
download "$work" linux-x86_64
equal 'exits 0' "$status" 0
exists 'the binary is where it says it is' "$work/repo/bin/linux-x86_64/basis"
equal 'and it is the file that was published' \
  "$(cat "$work/repo/bin/linux-x86_64/basis" 2>/dev/null)" 'the linux binary'
check 'and it is executable' \
  "$([ -x "$work/repo/bin/linux-x86_64/basis" ] && echo yes || echo no)"
absent 'the copied checksum file does not stay behind' \
  "$work/repo/bin/linux-x86_64/.sha256.check"
equal 'and neither does anything else the run used' \
  "$(hidden "$work/repo/bin/linux-x86_64")" ''
cleanup "$work"

case_ 'a tampered download is refused'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'not what was signed off' 'the linux binary'
download "$work" linux-x86_64
check 'exits non-zero' "$([ "$status" -ne 0 ] && echo yes || echo no)"
mentions 'and says so' 'FAILED'
absent 'and keeps none of what it downloaded' "$work/repo/bin/linux-x86_64/basis"
equal 'not even half-way' "$(hidden "$work/repo/bin/linux-x86_64")" ''
cleanup "$work"

# The case above starts from an empty bin/. This one starts from a binary that
# was verified on an earlier run, which is what an upgrade looks like -- and a
# download that fails must not be able to replace it.
case_ 'a download that fails verification leaves the binary already there alone'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the v0.1.0 binary'
download "$work" linux-x86_64
equal 'v0.1.0 is verified and kept' "$status" 0
publish "$work" v0.2.0 linux-x86_64 basis 'not what was signed off' 'the v0.2.0 binary'
download "$work" linux-x86_64
check 'v0.2.0 is refused' "$([ "$status" -ne 0 ] && echo yes || echo no)"
equal 'and the binary is still the verified v0.1.0' \
  "$(cat "$work/repo/bin/linux-x86_64/basis" 2>/dev/null)" 'the v0.1.0 binary'
equal 'with nothing left beside it' "$(hidden "$work/repo/bin/linux-x86_64")" ''
cleanup "$work"

case_ 'an upgrade that does verify replaces the binary'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the v0.1.0 binary'
download "$work" linux-x86_64
publish "$work" v0.2.0 linux-x86_64 basis 'the v0.2.0 binary'
download "$work" linux-x86_64
equal 'exits 0' "$status" 0
equal 'and v0.2.0 is what is there now' \
  "$(cat "$work/repo/bin/linux-x86_64/basis" 2>/dev/null)" 'the v0.2.0 binary'
check 'and it is executable' \
  "$([ -x "$work/repo/bin/linux-x86_64/basis" ] && echo yes || echo no)"
cleanup "$work"

# Not a mismatch this time: the asset never arrives. Before the staging
# directory, a transfer that broke off over an existing binary left the part
# that did arrive in its place, still executable.
case_ 'a download that does not arrive leaves nothing behind'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the linux binary'
rm "$work/releases/v0.1.0/basis-linux-x86_64"
download "$work" linux-x86_64
check 'exits non-zero' "$([ "$status" -ne 0 ] && echo yes || echo no)"
absent 'and keeps nothing' "$work/repo/bin/linux-x86_64/basis"
equal 'not even half-way' "$(hidden "$work/repo/bin/linux-x86_64")" ''
cleanup "$work"

case_ 'the windows asset name is mapped, and the bare name is kept'
work="$(sandbox)"
publish "$work" v0.1.0 windows-x86_64 basis.exe 'the windows binary'
download "$work" windows-x86_64
equal 'exits 0' "$status" 0
exists 'basis.exe is saved under its bare name' \
  "$work/repo/bin/windows-x86_64/basis.exe"
mentions 'and the platform was in the asset name' 'basis-windows-x86_64.exe'
cleanup "$work"

case_ 'a platform this repository knows nothing about is an error, not a download'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the linux binary'
download "$work" darwin-arm64
equal 'exits 1' "$status" 1
mentions 'and says there is no checksum file' 'no checksum file'
mentions 'and lists the versions it does know' 'v0.1.0'
mentions 'and the platforms it does know' 'linux-x86_64'
absent 'nothing was written' "$work/repo/bin/darwin-arm64"
cleanup "$work"

case_ 'the newest version is the highest, not the last alphabetically'
work="$(sandbox)"
publish "$work" v0.2.0 linux-x86_64 basis 'the older binary'
publish "$work" v0.10.0 linux-x86_64 basis 'the newer binary'
download "$work" linux-x86_64
equal 'exits 0' "$status" 0
equal 'v0.10.0 beats v0.2.0' \
  "$(cat "$work/repo/bin/linux-x86_64/basis" 2>/dev/null)" 'the newer binary'
mentions 'and it says which one it took' 'v0.10.0'
cleanup "$work"

case_ 'BASIS_CLI_VERSION asks for another one'
work="$(sandbox)"
publish "$work" v0.2.0 linux-x86_64 basis 'the older binary'
publish "$work" v0.10.0 linux-x86_64 basis 'the newer binary'
out="$(cd "$work/repo" && BASIS_CLI_BASE_URL="file://$work/releases" \
  BASIS_CLI_VERSION=v0.2.0 ./download.sh linux-x86_64 2>&1)"; status=$?
equal 'exits 0' "$status" 0
equal 'and v0.2.0 is what arrives' \
  "$(cat "$work/repo/bin/linux-x86_64/basis" 2>/dev/null)" 'the older binary'
cleanup "$work"

case_ 'with nothing to check the checksum with, it refuses instead of guessing'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the linux binary'
# A PATH with just enough to get as far as the check and no further: no
# sha256sum, no shasum, and no curl either -- reaching curl would already be
# the bug this case is about. `bash` is in the list because the shebang is
# `env bash`, and `env` looks it up in this PATH like anything else.
mkdir -p "$work/bin"
for tool in bash dirname basename sort tail; do
  ln -s "$(command -v "$tool")" "$work/bin/$tool"
done
out="$(cd "$work/repo" && PATH="$work/bin" BASIS_CLI_BASE_URL="file://$work/releases" \
  ./download.sh linux-x86_64 2>&1)"; status=$?
equal 'exits 1' "$status" 1
mentions 'and says why' 'cannot verify'
absent 'and nothing was downloaded' "$work/repo/bin/linux-x86_64/basis"
cleanup "$work"

case_ 'without curl it refuses before downloading'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the linux binary'
if command -v sha256sum >/dev/null 2>&1; then
  hash_tool=sha256sum
else
  hash_tool=shasum
fi
# The PATH of the shasum case below, minus curl: everything the script needs
# before and after the check is on it, so without the check it would get as
# far as curl itself and fail there. The hash tool is on it because that check
# comes first, and it is whichever one this machine has, as in `sum()`.
mkdir -p "$work/bin"
for tool in bash dirname basename sort tail mkdir mktemp cp mv rm chmod "$hash_tool"; do
  ln -s "$(command -v "$tool")" "$work/bin/$tool"
done
out="$(cd "$work/repo" && PATH="$work/bin" BASIS_CLI_BASE_URL="file://$work/releases" \
  ./download.sh linux-x86_64 2>&1)"; status=$?
equal 'exits 1' "$status" 1
# Not just 'curl': bash's own "curl: command not found" contains that too, so
# only the script's message and the missing directory tell the check happened.
mentions 'and says why' 'curl not found'
absent 'and nothing was written' "$work/repo/bin/linux-x86_64"
cleanup "$work"

case_ 'without sha256sum it falls back to shasum, which is all older macOS has'
if command -v shasum >/dev/null 2>&1; then
  work="$(sandbox)"
  publish "$work" v0.1.0 linux-x86_64 basis 'the linux binary'
  # The same trick as the two cases above: this PATH has shasum and everything
  # the download itself needs, but no sha256sum. It is the only way to reach
  # that branch on a machine that has both.
  mkdir -p "$work/bin"
  for tool in bash dirname basename sort tail curl mkdir mktemp cp mv rm chmod shasum; do
    ln -s "$(command -v "$tool")" "$work/bin/$tool"
  done
  out="$(cd "$work/repo" && PATH="$work/bin" BASIS_CLI_BASE_URL="file://$work/releases" \
    ./download.sh linux-x86_64 2>&1)"; status=$?
  equal 'exits 0' "$status" 0
  exists 'and the binary is verified and kept' "$work/repo/bin/linux-x86_64/basis"
  cleanup "$work"
else
  printf '  skip  no shasum on this machine\n'
fi

case_ 'a checksum file with several entries brings all of them'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the binary'
publish "$work" v0.1.0 linux-x86_64 basis.sig 'the signature'
download "$work" linux-x86_64
equal 'exits 0' "$status" 0
exists 'the first is here' "$work/repo/bin/linux-x86_64/basis"
exists 'and so is the second' "$work/repo/bin/linux-x86_64/basis.sig"
cleanup "$work"

case_ 'one tampered entry keeps the whole set out'
work="$(sandbox)"
publish "$work" v0.1.0 linux-x86_64 basis 'the binary'
publish "$work" v0.1.0 linux-x86_64 basis.sig 'not what was signed off' 'the signature'
download "$work" linux-x86_64
check 'exits non-zero' "$([ "$status" -ne 0 ] && echo yes || echo no)"
mentions 'and says which one' 'basis.sig: FAILED'
absent 'and the entry that matched is not kept either' \
  "$work/repo/bin/linux-x86_64/basis"
equal 'nor anything half-way' "$(hidden "$work/repo/bin/linux-x86_64")" ''
cleanup "$work"

# `sha256sum -c` warns about a line it cannot parse and still exits 0 when
# another line checks out, so each of these second entries would have been
# fetched and never verified. A single space is the likeliest typo of the three.
case_ 'a checksum line that is not exactly <sha256>  <name> is refused, not skipped'
for shape in one-space not-hex hidden-name; do
  work="$(sandbox)"
  publish "$work" v0.1.0 linux-x86_64 basis 'the binary'
  publish "$work" v0.1.0 linux-x86_64 basis.sig 'the signature'
  f="$work/repo/checksums/v0.1.0/linux-x86_64.sha256"
  case "$shape" in
    (one-space)   sed 's/  basis\.sig$/ basis.sig/' "$f" > "$f.new" ;;
    (not-hex)     sed 's/^[0-9a-f]\(.*  basis\.sig\)$/g\1/' "$f" > "$f.new" ;;
    (hidden-name) sed 's/  basis\.sig$/  .basis.sig/' "$f" > "$f.new" ;;
  esac
  mv "$f.new" "$f"
  download "$work" linux-x86_64
  equal "$shape: exits 1" "$status" 1
  mentions "$shape: and says why" 'has a line that is not'
  absent "$shape: and keeps nothing" "$work/repo/bin/linux-x86_64/basis"
  cleanup "$work"
done

case_ 'a checksum file that lists nothing is refused'
work="$(sandbox)"
mkdir -p "$work/repo/checksums/v0.1.0"
: > "$work/repo/checksums/v0.1.0/linux-x86_64.sha256"
download "$work" linux-x86_64
equal 'exits 1' "$status" 1
mentions 'and says why' 'lists nothing'
cleanup "$work"

# --------------------------------------------------------------------------

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
