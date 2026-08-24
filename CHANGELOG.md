# Changelog

## v0.1.0 — 2026-08-23

First tagged release. The binaries themselves are not new — they are the ones
that have been running against the devnet — but until now they had no version
number, only the date they were copied.

- `linux-x86_64` and `windows-x86_64` builds of `basis`, attached to the
  [v0.1.0 release](https://github.com/basis-network/basis-cli/releases/tag/v0.1.0).
- `checksums/v0.1.0/` holds the SHA-256 of each binary. Verified with
  `download.sh`, which never downloads the checksum.
- This release is **not signed**: it predates the signing workflow. Releases
  from v0.1.1 onwards are signed with cosign in keyless mode.

### `basis-node` is no longer distributed here

Earlier checksum files covered `basis-node` as well as `basis`. They no longer
do, and the node binary is not published under this prefix.

This is a deliberate change to what this repository vouches for, not
housekeeping. Basis is a permissioned network: there is no third-party node
operation to support, so shipping a node binary to the public promised
something that was never on offer. Node builds stay internal.

If you were verifying a `basis-node` download against a checksum from this
repository, that path is gone.

### Known issues

Carried over from the builds, documented in the README: 20-byte query
addresses against 32-byte accounts, wrong unit names in printed balances, no
way to send HTTP headers, and embedded TLS roots that break behind corporate
TLS inspection. No macOS build.
