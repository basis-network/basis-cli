# Assurance case

An argument, with the evidence attached, that this project meets the security
requirements stated in [SECURITY.md](../SECURITY.md#security-requirements).

It is written to be argued with. Where the argument is weak, it says so —
an assurance case that only lists strengths is a brochure.

**Last reviewed: 2026-08-24.** See [Security review](#security-review) for what
the review consisted of.

---

## 1. The claim

> The bytes a user ends up executing are the bytes whose SHA-256 digest was
> committed to this repository and reviewed before the release existed — or
> the tool refuses and says why.

Everything below argues for that one sentence. Note what it does **not** claim:
nothing here asserts that the binary is correct, that it is free of
vulnerabilities, or that it was compiled from any particular source. Those are
properties of `basis-core`, which is not public and is outside this security
boundary. Claiming them would be the most tempting lie in this document.

## 2. The security boundary

Detailed in [ARCHITECTURE.md](./ARCHITECTURE.md#trust-boundaries). In short,
four regions:

| Region | Trusted? | Why |
|---|---|---|
| The network and the CDN serving releases | **No** | Anyone between the user and GitHub, plus anyone who can push an asset |
| Release assets | **No, until verified** | Mutable by whoever holds repository write access |
| This git repository | **Yes, and reviewable** | Protected branch, linear history, every change a PR with a diff |
| `basis-core` | **Out of scope** | Not public. This repository makes no claim about it |

The security-relevant boundary crossing is exactly one: **untrusted bytes
entering a machine, checked against a digest that came the other way.**

## 3. Threat model

Adversaries, by what they can do rather than who they are.

### T1 — Network attacker (in the path, no credentials)

*Can:* intercept, delay or replace the HTTPS response carrying the binary.

*Countered by:* the digest is not on the wire. `download.sh` reads
`checksums/<tag>/<platform>.sha256` from the working tree and **never
downloads it**. Substituted bytes fail `sha256sum -c`, the script exits
non-zero, and nothing is made executable.

*Evidence:* `test/run.sh` case *"a tampered download is refused"* — the fixture
publishes one payload and records the digest of a different one, then asserts a
non-zero exit and `FAILED` in the output. Verified by mutation: disabling the
check turns the suite red.

*Residual risk:* TLS itself is trusted for confidentiality, not integrity. If
TLS were fully broken the checksum still holds. **This is the strongest part of
the design.**

### T2 — Release attacker (can replace a published asset)

*Can:* upload a different `basis-linux-x86_64` to an existing release.

*Countered by:* same mechanism, different reason. The digest lives in git,
committed *before* the release is published. Replacing the asset does not
change the digest, so verification fails on every user's machine at once and
loudly.

*Evidence:* `release.yml` re-verifies every published asset against
`checksums/<tag>/` on `release: published`, and can be re-run by
`workflow_dispatch` without republishing. A mismatch fails the workflow.

*Residual risk:* an attacker who replaces the asset **and** waits for a release
that has no committed checksum would not be caught. Mitigated by the ordering
rule in [GOVERNANCE.md](../GOVERNANCE.md#releases): checksums are committed
before the release is published, and `release.yml` fails when
`checksums/<tag>/` does not exist.

### T3 — Repository attacker (can push to `main`)

*Can:* change the checksum to match a malicious binary.

*Countered by:* not prevented — **made visible.** `main` is protected: no
force-push, linear history, required status checks, changes through pull
requests. A modified digest is a diff on a public branch with an author and a
date. Detection, not prevention, is the honest description.

*Residual risk:* **this is the weakest link, and it is a single maintainer.**
One person's compromised account can push both a poisoned checksum and a
matching release. Two maintainers with independent credentials and mandatory
2FA at the organisation level reduce the blast radius; they do not eliminate
it. Genuine mitigation is `two_person_review` — every change reviewed by
someone other than its author — which this project **does not yet meet** and
names as its main open gap in [ROADMAP.md](./ROADMAP.md).

### T4 — Compromised CI

*Can:* alter what the workflows do, or exfiltrate a token.

*Countered by:* `permissions: read-all` at workflow level, elevated per job
only where required (`contents: write` and `id-token: write` in `release.yml`
alone). Every action pinned to a **commit SHA**, never a tag — a tag is
mutable, and whoever can move it changes what runs. `persist-credentials:
false` on every checkout. Dependabot watches the pins so "pinned" does not
quietly become "stale". CodeQL analyses the workflows as code.

*Residual risk:* GitHub Actions itself is trusted. Keyless signing means there
is no long-lived private key to steal; it also means the signing identity *is*
the workflow, so a compromised workflow signs happily. The Rekor transparency
log makes such a signature permanent and public, which is the point.

### T5 — Malicious or careless user environment

*Can:* run the script with no SHA-256 tool, a mutilated `PATH`, a hostile
`TMPDIR`, or attacker-influenced arguments.

*Countered by:* fail-closed. No `sha256sum` and no `shasum` means exit 1
**before any network access** — the tool refuses rather than fetching what it
cannot check. An unknown platform is an error that lists what is known, not a
guess.

*Evidence:* cases *"with nothing to check the checksum with, it refuses instead
of guessing"* (asserts nothing was downloaded) and *"a platform this repository
knows nothing about is an error, not a download"*.

### T6 — Supply chain of the tooling itself

*Can:* compromise `curl`, bash, or a GitHub Action.

*Countered by:* the dependency surface is deliberately tiny — bash, `curl`, a
SHA-256 tool, all from the operating system and updated by it. No package
manifest, no vendored code, nothing from a language registry. Actions are
SHA-pinned and Dependabot-watched.

*Residual risk:* accepted. A compromised system `curl` defeats any script that
uses it, and the alternative — shipping a fetcher — would be worse.

## 4. Secure design principles

Against Saltzer and Schroeder, with the honest answer in each row.

| Principle | How it is applied |
|---|---|
| **Fail-safe defaults** | Every path denies by default: no checksum file → exit; no hash tool → exit; digest mismatch → exit non-zero. The binary is made executable only after verification succeeds |
| **Economy of mechanism** | ~110 lines of bash, no dependency manifest, no configuration file, no persistent state. The whole verification argument fits on one page. This is the principle the design leans on hardest |
| **Complete mediation** | Every downloaded artefact is checked. The loop verifies *each* name in the checksum file, not just the first — covered by the multi-entry case in the suite |
| **Open design** | Security rests on where the digest travels, not on anything secret. Every line is public and Apache-2.0. There is no private signing key at all |
| **Separation of privilege** | The core of the design: subverting a download requires control of **both** the release and the git history. Two mechanisms, two audiences, different failure modes |
| **Least privilege** | Workflows are `read-all` by default, elevated per job only where needed. The script needs no privilege and asks for none; it writes only under its own `bin/` |
| **Least common mechanism** | Each test case builds its own throwaway world under its own temporary directory; no shared fixture, nothing committed |
| **Psychological acceptability** | One command, no flags required. The failure message names the file and says `cannot verify, refusing to continue` rather than a status code. If verifying were harder than not verifying, people would not verify |

## 5. Common implementation weaknesses

The CWE/SANS and OWASP lists are written for applications with parsers,
databases and sessions. Only a few entries have any meaning for a download
script; those are answered, and the rest are named as not applicable rather
than quietly skipped.

| Weakness | Status |
|---|---|
| **CWE-494** Download of code without integrity check | **This is the weakness the repository exists to counter.** See §3 T1/T2 |
| **CWE-347** Improper verification of signature | Verification is `sha256sum -c`, the platform tool, not a hand-rolled comparison. Release assets additionally carry a Sigstore bundle |
| **CWE-829** Inclusion of functionality from untrusted control sphere | The checksum is never fetched; that is the whole point. `BASIS_CLI_BASE_URL` exists for the test suite and defaults to the official release URL |
| **CWE-78** OS command injection | Every expansion is quoted; `shellcheck` runs in CI over both scripts and fails the build. The file names come from a checksum file whose format CI validates (64 hex characters, and a name that must be `basis` or `basis.exe`) |
| **CWE-22** Path traversal | Same control: `lint.yml` rejects any checksum line whose name is not one of the two expected. A `../` name never reaches the download loop |
| **CWE-367** TOCTOU | The verified file is the file kept. Nothing is re-fetched or replaced between checking and use |
| **CWE-improper-cleanup** | The copied checksum file is removed after verification; the suite asserts it does not stay behind |
| **CWE-798** Hard-coded credentials | There are none. The script authenticates to nothing, and nothing in this repository reads a keystore or asks for a passphrase |
| **CWE-311** Missing encryption | Transport is HTTPS by default; `curl` verifies certificates by default and no flag here disables it |
| Injection, XSS, deserialisation, SQL, session and access-control weaknesses | **Not applicable.** No parser, no database, no session, no privilege model, no web surface |

## 6. Evidence, in one place

| Claim | Where to check it |
|---|---|
| The refusals refuse | `test/run.sh` — 9 cases, 28 assertions, run on every push and pull request |
| The suite reaches the code | `make coverage` — 98.1% statement coverage of `download.sh`, enforced at 90% in CI |
| The script is statically clean | `shellcheck` in `lint.yml`, required before merge |
| Workflows are analysed as code | CodeQL `actions` support, `codeql.yml` |
| Checksum files cannot smuggle a name | `lint.yml`, job *checksum files are well formed* |
| Published assets match what was committed | `release.yml`, verify step |
| Signatures are public and permanent | Sigstore keyless; certificates in the Rekor transparency log |
| Dependencies do not rot while pinned | `dependabot.yml`, weekly |
| The project is scored by someone else | OpenSSF Scorecard, published on every push |

## 7. Security review

**2026-08-24.** Carried out by the maintainer against the security requirements
in SECURITY.md and the boundary in §2: the threat model was re-derived from
the current code rather than inherited, all nine test cases were read against
the claims they are cited for, coverage was measured rather than assumed
(98.1%), and every workflow was re-read for permission scope and pinning.

Tool support: `shellcheck` (static), CodeQL over the workflows, OpenSSF
Scorecard, and the test suite as dynamic exercise of the failure paths. Tools
did not find the two findings below; reading did.

**Findings.**

1. **Single-maintainer review remains the dominant residual risk** (T3). Not
   fixable by writing; recorded in ROADMAP.md and GOVERNANCE.md, and answered
   *Unmet* in the badge rather than argued around.
2. **The Windows build has no recorded provenance.** It predates the practice
   and ships as-is, documented in the README. No new asset ships without it.

Neither is a vulnerability in what this repository does; both are limits on
what it can vouch for, which is why they are written down instead of resolved
on paper.

## 8. Known gaps

Restated together, because a reader deserves them in one place rather than
scattered through an argument:

- **No second reviewer.** One person can currently push a poisoned checksum and
  a matching binary. This is the real one.
- **`basis-core` is not public**, so nothing here attests to the binary's
  behaviour — only to its identity.
- **The Windows binary is not reproducible** and its source commit was not
  recorded.
- **No branch-coverage measurement**, because no FLOSS tool measures branch
  coverage for shell.
- **No fuzzing.** There is no parser here to fuzz; the inputs are a platform
  name and a checksum file whose format CI validates.
