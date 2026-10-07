# Changelog

## Unreleased

The list below does not change what gets downloaded or how it is verified: it
makes the verification checked by something other than a person reading the
script. What did change in `download.sh` has its own heading after the list.

- `test/run.sh` — a test suite for `download.sh`, run by `make check` and by CI
  on every pull request. Each case builds a throwaway release in a temporary
  directory and reaches it over `file://`: no network, and no fixture
  committed. Two of the cases are the failure paths — a tampered download and a
  machine with nothing to hash with — because a refusal that stops working
  fails silently.
- `Makefile` with `check` and `lint`, so both are one word.
- Vulnerabilities can now be reported through a
  [private GitHub advisory](https://github.com/basis-network/basis-cli/security/advisories/new)
  as well as by email. See [SECURITY.md](./SECURITY.md).

### A download that failed could replace a verified binary

[GHSA-6g2j-56rg-33x4][ghsa]. Every earlier `download.sh` is affected, including
the one in the v0.1.0 tag.

`download.sh` used to fetch each asset straight into `bin/<platform>/` and check
it there. On a first run that did no harm. On any later run — an upgrade, or
the same version fetched again — the download overwrote the binary already
there *before* it was checked, and an overwritten file keeps its mode. A
mismatch still said `FAILED` and exited non-zero, and a transfer that broke off
still exited non-zero, but in both cases the file under the name people run was
now the unverified one, and it was executable. That broke the guarantee in
[SECURITY.md](./SECURITY.md) that nothing unverified is ever made executable. If
`bin/<platform>/basis` was a symlink or a hard link, the bytes went to its
target instead.

Taking advantage of it needed the position verification exists to defeat — a
replaced release asset, or a broken TLS connection — and someone running
`basis` after the script had failed. The v0.1.0 assets still match the
checksums committed for them (checked on 2026-10-06).

Now every asset is fetched and checked in a staging directory inside
`bin/<platform>/`, and only a set that has passed in full is moved into place,
one rename per file. A run that fails or is cut short leaves what was already
there as it was. Four other things were tightened on the way, because each one
was another route by which an unchecked file could reach the same place:

- A checksum line that is not exactly `<sha256>  <name>` is refused. Before,
  `sha256sum -c` warned about it, checked the other lines, exited 0, and the
  asset on the bad line was installed without being checked.
- A checksum file that lists nothing is refused, instead of reporting success.
- A failed check stops the script explicitly. Before, it relied on `set -e`,
  and a bash 3.2 built from GNU sources does not stop when a `( subshell )`
  fails.
- A symlink or hard link at `bin/<platform>/basis` is replaced, not written
  through.

`test/run.sh` covers each of these, and the upgrade both ways: one that fails
leaves the old binary, one that verifies replaces it.

If a run of `download.sh` ever failed, or was interrupted, on a machine that
already had a `bin/<platform>/basis`, delete `bin/` and run the script again
before using it. Or check what is there against the version you meant to
install (`shasum -a 256 -c` on a Mac without `sha256sum`):

```bash
cd bin/linux-x86_64 && sha256sum -c ../../checksums/v0.1.0/linux-x86_64.sha256
```

[ghsa]: https://github.com/basis-network/basis-cli/security/advisories/GHSA-6g2j-56rg-33x4

## v0.1.0 — 2026-08-23

First tagged release. The binaries themselves are not new — they are the ones
that have been running against the devnet — but until now they had no version
number, only the date they were copied.

- `linux-x86_64` and `windows-x86_64` builds of `basis`, attached to the
  [v0.1.0 release](https://github.com/basis-network/basis-cli/releases/tag/v0.1.0).
- `checksums/v0.1.0/` holds the SHA-256 of each binary. Verified with
  `download.sh`, which never downloads the checksum.
- Assets are signed with cosign in keyless mode by the release workflow, which
  first verifies each one against `checksums/v0.1.0/`. Verify with:

  ```bash
  cosign verify-blob basis-linux-x86_64 \
    --bundle basis-linux-x86_64.sigstore \
    --certificate-identity-regexp \
      'https://github.com/basis-network/basis-cli/.github/workflows/release.yml@.*' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com
  ```

  *(The annotated git tag for v0.1.0 says this release is unsigned. It was
  written minutes before the workflow ran and proved otherwise. The tag is left
  where it is rather than moved: a published tag that shifts under people is a
  worse problem than a stale sentence in its message.)*

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
