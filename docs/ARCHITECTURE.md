# Architecture

What this repository produces, what its parts are, and how they fit together.

**Scope.** This document describes *this repository* — the tooling that
distributes and verifies the Basis CLI. It does not describe the CLI binary's
internals: that is built from `basis-core`, which is not public. The boundary
between the two is itself part of the architecture and is drawn explicitly
below.

## The one-sentence version

A release serves the binary and git serves the checksum, and the whole design
exists so that **no single party controls both**.

## Components

| Component | What it is | What it is responsible for |
|---|---|---|
| `download.sh` | ~110 lines of bash, no dependencies beyond `curl` and a SHA-256 tool | Fetch an asset, verify it against the committed checksum, refuse if it cannot |
| `checksums/<tag>/<platform>.sha256` | Plain text, committed to git | The trust anchor. Each line is a digest and the bare file name it belongs to |
| `.github/workflows/release.yml` | Runs when a release is **published** | Verify every published asset against `checksums/`, then sign it with cosign |
| `.github/workflows/test.yml` | Runs on push and pull request | Run the suite; measure statement coverage of `download.sh` |
| `.github/workflows/lint.yml` | Runs on push and pull request | `shellcheck`; `reuse lint`; checksum files are well formed |
| `.github/workflows/codeql.yml` | Runs on push, pull request, weekly | CodeQL over the workflows themselves |
| `.github/workflows/scorecard.yml` | Runs on push, weekly | Publish an OpenSSF Scorecard result anyone can read |
| `test/run.sh` | Nine cases, no framework, no network | Prove the refusals still refuse |
| `test/coverage.sh` | bashcov + a per-line union across sandboxes | Put a number on what the suite reaches |

Nothing here is a library, a service, or a daemon. There is no state that
survives a run, no configuration file, and no network listener.

## How a download actually works

```
     git (this repository)                    GitHub releases
     checksums/v0.1.0/linux-x86_64.sha256     basis-linux-x86_64
              │                                       │
              │  read from disk                       │  curl over HTTPS
              │  NEVER downloaded                     │
              ▼                                       ▼
           ┌──────────────────────────────────────────────┐
           │              download.sh                      │
           │  1. resolve version   (newest in checksums/)  │
           │  2. resolve platform  (argument, default      │
           │     linux-x86_64)                             │
           │  3. refuse if there is no checksum file       │
           │  4. refuse if there is no SHA-256 tool        │
           │  5. fetch each asset named in the checksum    │
           │  6. verify, and only then keep it             │
           └──────────────────────────────────────────────┘
                                │
                                ▼
                        bin/<platform>/basis
```

Five properties of that flow are load-bearing, and each has a test:

1. **The checksum is never fetched.** It is read from the working tree. A
   checksum downloaded alongside the binary would be a mirror of whatever the
   release happens to serve, and would prove nothing.
2. **Verification precedes use.** The file is written, checked, and only then
   made executable. A mismatch exits non-zero and says `FAILED`.
3. **No verifier means no download.** If neither `sha256sum` nor `shasum`
   exists, the script exits before touching the network rather than fetching
   something it cannot check.
4. **The version is chosen by sort order, not by string order.** `v0.10.0`
   beats `v0.2.0`.
5. **Assets are renamed on the way in.** A release is one flat namespace, so
   assets carry the platform (`basis-linux-x86_64`); the checksum file lists
   the bare name the user ends up with (`basis`).

## Trust boundaries

```
┌─ untrusted ───────────────────────────────────────────────────┐
│  the network, the CDN serving the release, the release assets  │
└───────────────────────────────────────────────────────────────┘
                     │  crosses into
                     ▼
┌─ verified on arrival ─────────────────────────────────────────┐
│  bytes written under bin/, checked against a digest from git   │
└───────────────────────────────────────────────────────────────┘

┌─ trusted, and reviewable ─────────────────────────────────────┐
│  this git repository: script, checksums, workflows.            │
│  Every change has a commit, an author, a diff and a PR.        │
└───────────────────────────────────────────────────────────────┘

┌─ outside this repository ─────────────────────────────────────┐
│  basis-core, which compiles the binary. Not public. Its        │
│  correctness is NOT something this repository can attest to.   │
└───────────────────────────────────────────────────────────────┘
```

The boundary that matters is the third against the first. An attacker who can
replace a release asset cannot also rewrite a committed checksum without
leaving a diff on a protected branch; an attacker who can push to `main`
cannot make an already-published binary match a new digest. Compromising the
download requires both, through two mechanisms that fail differently and are
watched by different people.

**What this architecture does not claim.** That the binary is free of defects,
that it does what its documentation says, or that `basis-core` was built from
the source it claims. Those are properties of a repository that is not this
one. What is claimed is narrower and checkable: *the bytes you end up with are
the bytes whose digest was committed here.*

## The publishing side

`release.yml` fires on `release: published`, deliberately not on a tag push:
what it checks is what people will actually download, not a rebuild that
resembles it. It downloads the published assets, verifies each against
`checksums/<tag>/`, and signs each with cosign in **keyless** mode — the
identity is the workflow's OIDC token, and the certificate goes to the public
Rekor transparency log. There is no private key to steal, and none on the site
that serves the downloads.

That ordering is the point: **checksums are committed before the release is
published.** The digest exists, reviewed, before there is a binary to match it.

## Why bash, and what that costs

The script has to run on a machine that has nothing installed yet — that is
the situation it exists for. Bash, `curl` and a SHA-256 tool are present on a
stock Linux and macOS; anything richer would mean installing something before
you can safely install anything.

The cost is real and worth stating: no type system, no dependency manifest,
and failure modes that are easy to write by accident. `set -euo pipefail`,
`shellcheck` in CI, and a suite that exercises the refusal paths are what is
put against that.

## Documents next to this one

| | |
|---|---|
| [ASSURANCE-CASE.md](./ASSURANCE-CASE.md) | why the security requirements are met, argued against a threat model |
| [ROADMAP.md](./ROADMAP.md) | what the project intends to do, and what it does not |
| [../SECURITY.md](../SECURITY.md) | the security requirements themselves, and how to report a problem |
