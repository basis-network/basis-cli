# Basis CLI

[![lint](https://github.com/basis-network/basis-cli/actions/workflows/lint.yml/badge.svg)](https://github.com/basis-network/basis-cli/actions/workflows/lint.yml)
[![test](https://github.com/basis-network/basis-cli/actions/workflows/test.yml/badge.svg)](https://github.com/basis-network/basis-cli/actions/workflows/test.yml)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/14224/badge)](https://www.bestpractices.dev/projects/14224)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/basis-network/basis-cli/badge)](https://scorecard.dev/viewer/?uri=github.com/basis-network/basis-cli)
[![REUSE status](https://api.reuse.software/badge/github.com/basis-network/basis-cli)](https://api.reuse.software/info/github.com/basis-network/basis-cli)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](./LICENSE)

The command-line client for [Basis Network](https://basisnetwork.com.co):
create wallets, query the chain, transfer LITHOS and deploy contracts.

It is **the only tool that can currently sign for this network.** Basis signs
with ML-DSA-65 (FIPS 204, post-quantum), so no Ethereum wallet can produce a
valid transaction for it — the signature scheme is different, not just the
curve.

> The network is a **development network**. Nothing here is production, LITHOS
> has no value, and the chain may be reset without notice.

---

## Install

```bash
git clone https://github.com/basis-network/basis-cli.git
cd basis-cli
./download.sh                    # linux-x86_64
./download.sh windows-x86_64
```

The script downloads the binary and verifies it before handing it to you. It
refuses to continue if it cannot verify.

By hand, if you prefer:

```bash
VERSION=v0.1.0
curl -fSLO "https://github.com/basis-network/basis-cli/releases/download/$VERSION/basis-linux-x86_64"
mv basis-linux-x86_64 basis
sha256sum -c checksums/$VERSION/linux-x86_64.sha256
chmod +x basis
```

Release assets carry the platform in their name because a release is one flat
namespace; the checksum files list the bare name you end up with.

## Why this repository exists

The binaries are not in it. They are megabytes each and git never forgets: ten
releases would live in every clone forever, and taking them out afterwards
means rewriting history. They are attached to
[GitHub releases](https://github.com/basis-network/basis-cli/releases) instead,
which keeps them out of the tree.

What *is* in here is `checksums/`, and that is the point:

**The binary travels through the release. The checksum travels through git** —
where it has a commit, an author, a date and a diff anybody can read. Checking
one against the other is what makes keeping them apart safe. A checksum stored
next to the file it describes proves nothing: whoever can replace one can
replace the other.

That is also why `download.sh` never downloads the checksum, and why
[the release workflow](./.github/workflows/release.yml) verifies every
published asset against the committed checksums before signing it.

Assets are signed with [Sigstore](https://www.sigstore.dev/) cosign in keyless
mode — there is no private key, and the certificate is in the public Rekor
transparency log. See [SECURITY.md](./SECURITY.md#signatures) to verify one.

## Where the source is

Not here. The CLI is built from `basis-core`, the node workspace, which is not
public yet. This repository distributes the compiled tool and documents it. See
[CONTRIBUTING.md](./CONTRIBUTING.md) for what that means for patches.

## Commands

```
basis wallet new|import          ML-DSA-65 wallet (encrypted keystore)
basis validator-key new|import   Validator keys
basis balance|nonce|block        State queries
basis tx-receipt                 Transaction receipt
basis send tx                    Transfer, call a contract, or deploy one
```

The endpoint goes in `--rpc-url` or in the `BASIS_RPC_URL` environment
variable. The public devnet endpoint and how to get a token are documented at
[basisnetwork.com.co/docs](https://basisnetwork.com.co/docs).

## Things worth knowing before you use it

Everything below is measured against the running devnet, not assumed. These are
rough edges of this build, and they are written down because each one costs an
afternoon to find on your own.

### Queries want 20 bytes; accounts are 32

A Basis account is `BLAKE3(ML-DSA-65 public key)` — 32 bytes, and that is what
`wallet new` prints. But `balance`, `nonce` and `tx-receipt` want 40 hex
characters, and you must give them the **last** 20 bytes of that identity:

```
identity      0x0ad5fa7d057384f38e4b3c81f68af934d5547d6e2214f44d56dc0077aec217f6
for balance                             0xf68af934d5547d6e2214f44d56dc0077aec217f6
```

Passing the **first** 20 bytes does not error. It answers `balance 0`, which
reads exactly like an empty account. `--to` on `send tx` does take the full
32-byte form.

### It prints the wrong units

It shows `4985159985308 wei (0.000005 eth-equivalent)`. The unit is the
**tomo**, the currency is **LITHOS**, and 1 LITHOS = 10⁹ tomos — not the 10¹⁸
the CLI assumes when it divides. The raw number is right; the conversion and
the names are not.

### It cannot send HTTP headers

There is no `--rpc-token` and no way to set `Authorization: Bearer`. That is why
third-party RPC access carries the token in the path instead.

### It carries its own TLS roots

It uses rustls with embedded roots and does not read the system certificate
store. `SSL_CERT_FILE` has no effect, and there is no `--cacert` or
`--insecure`. Behind corporate TLS inspection — a FortiGate, a Zscaler — every
HTTPS call fails with `send: error sending request`. The way around it is a
local HTTP proxy that forwards to the node.

## Builds

| Platform | Provenance |
|---|---|
| `linux-x86_64` | Built from `basis-core` `f74b78e` with `rustc` 1.96.1 inside `rust:1.96-bookworm` (Debian 12, glibc 2.36). Links only `libc`, `libm` and `libgcc_s` — no `libssl`, the workspace uses rustls. This is the build running on the devnet. |
| `windows-x86_64` | An earlier build. Not reproducible: the commit it came from was not recorded. It works, and it is shipped as-is. |

**There is no macOS build.** It is the most visible gap for anyone outside the
team, and it is on the list.

## Tests

```bash
make check
```

Each case builds a throwaway release in a temporary directory and points
`download.sh` at it over `file://`: no network, and nothing binary in the tree —
the fixtures are made at run time. Two of the cases are the failure paths, a
tampered download and a machine with nothing to hash with, because refusing
those is what this repository is for. CI runs the suite on every pull request.

How much of the script those cases actually reach is measured rather than
claimed:

```bash
make coverage       # needs bashcov: gem install bashcov
```

**98.1% statement coverage** of `download.sh`, 52 of 53 statements, enforced at
90% in CI.

## Project

| | |
|---|---|
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | the parts, how they fit, and where the trust boundaries are |
| [docs/ASSURANCE-CASE.md](./docs/ASSURANCE-CASE.md) | the threat model, and the argument that the security requirements hold |
| [docs/ROADMAP.md](./docs/ROADMAP.md) | what is planned, and what is deliberately not |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | what is accepted here, the coding style, how changes are reviewed, and the DCO sign-off |
| [SECURITY.md](./SECURITY.md) | reporting a vulnerability, verifying a download |
| [SUPPORT.md](./SUPPORT.md) | where to ask what |
| [GOVERNANCE.md](./GOVERNANCE.md) | who decides, and how |
| [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) | Contributor Covenant 2.1 |
| [CHANGELOG.md](./CHANGELOG.md) | what changed, and what it means |
| [test/](./test) | the suite, and what each case is guarding |

## Achievements

Every one of these is public, and every one links to the report rather than to
a marketing page — so you can check the claim instead of trusting the badge.

| | |
|---|---|
| [OpenSSF Best Practices](https://www.bestpractices.dev/projects/14224) | a self-assessment against the full criteria set, each answered in public with its reasoning |
| [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/basis-network/basis-cli) | scored automatically by someone else's tool, published on every push |
| [REUSE](https://api.reuse.software/info/github.com/basis-network/basis-cli) | every file carries its copyright and licence, checked in CI |

Worth knowing what they cover: **this repository** — the distribution and
verification tooling — not the compiled binary, whose source lives in
`basis-core`. The Best Practices entry says so itself rather than leaving it to
be discovered.

## License

[Apache License 2.0](./LICENSE). Copyright 2026 Basis Network
