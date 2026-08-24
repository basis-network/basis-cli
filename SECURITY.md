# Security Policy

## Reporting a vulnerability

Two private routes. Either is fine, and both reach the same people:

- **[Report a vulnerability](https://github.com/basis-network/basis-cli/security/advisories/new)**
  on GitHub. A private security advisory: visible to you and the maintainers,
  and to nobody else until it is published.
- **Email contact@basisnetwork.com.co** with `[security]` in the subject.

Please do not open a public issue.

Include what you can: what you did, what happened, what you expected, and the
version and platform. A proof of concept helps and is never required.

**What to expect**

| | |
|---|---|
| Acknowledgement | within 3 working days |
| First assessment | within 10 working days |
| Fix or a stated plan | within 90 days of the report |

If you do not hear back within those windows, assume the mail did not arrive
and send it again. We would rather read it twice than not at all.

We will tell you when we have a fix, credit you in the release notes unless you
ask us not to, and coordinate the timing of any public disclosure with you.
There is no bug bounty.

**How a report is handled**

1. **Acknowledged** to the reporter, and a GitHub private security advisory is
   opened if the report arrived by email, so that everything lives in one place
   with the reporter able to see it.
2. **Triaged**: reproduce it, decide whether it is inside this repository's
   security boundary (see
   [docs/ASSURANCE-CASE.md](./docs/ASSURANCE-CASE.md#2-the-security-boundary))
   or belongs to `basis-core` or the network. If it belongs elsewhere it is
   forwarded, and the reporter is told where it went.
3. **Severity and scope** are recorded in the advisory, along with which
   released versions are affected.
4. **Fixed** on a branch, with a regression test where the defect is testable
   from this repository, and reviewed before merge.
5. **Released**: a new version, checksums committed before publication, assets
   verified and signed by `release.yml`.
6. **Disclosed**: the advisory is published, the CHANGELOG says what changed
   and why, and the reporter is credited unless they asked otherwise. Timing is
   agreed with the reporter.

If a report turns out not to be a vulnerability, the reporter is told why
rather than left waiting.

## Supported versions

Only the latest release. This is a development network and the tool moves with
it; there are no long-term support branches.

| Version | Supported |
|---|---|
| v0.1.0 | yes |

## Verifying what you downloaded

Every release binary has a SHA-256 committed to this repository, under
[`checksums/`](./checksums). `download.sh` checks it and refuses to continue if
it cannot. By hand:

```bash
sha256sum -c checksums/v0.1.0/linux-x86_64.sha256
```

The checksum is deliberately kept **out of the release** that serves the
binary: a checksum stored next to the file it describes proves nothing, since
whoever can replace one can replace the other. Here the binary travels through
a GitHub release and the checksum travels through git, where it has a commit,
an author, a date and a diff. If the two disagree, trust neither and get in
touch.

### Signatures

Release assets are signed with [Sigstore](https://www.sigstore.dev/) cosign in
keyless mode by [`.github/workflows/release.yml`](./.github/workflows/release.yml).
There is no private signing key: the identity is the workflow's OIDC token and
the certificate is recorded in the public Rekor transparency log.

```bash
cosign verify-blob basis-linux-x86_64 \
  --bundle basis-linux-x86_64.sigstore \
  --certificate-identity-regexp \
    'https://github.com/basis-network/basis-cli/.github/workflows/release.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

This includes v0.1.0. The signature is not a promise about the binary's
history — it attests that these exact bytes were the ones this workflow
published, after checking them against the checksums committed here.

## Keys and keystores

`basis wallet new` writes an encrypted keystore. The passphrase is never
recoverable and is never transmitted. Nothing in this repository — including
`download.sh` — reads a keystore, asks for a passphrase, or touches key
material of any kind.

## Security requirements

What this tool guarantees, and what it does not. The argument that these are
actually met, with the threat model and the evidence, is in
[docs/ASSURANCE-CASE.md](./docs/ASSURANCE-CASE.md).

**What it guarantees**

1. **Integrity of what you download.** Any binary this tool hands you matches
   the SHA-256 committed to this repository for that version and platform. The
   checksum is read from your working tree and is never downloaded.
2. **It fails closed.** A digest that does not match, a version or platform
   with no committed checksum, or a machine with no SHA-256 tool all end in a
   non-zero exit and a message saying why. Nothing unverified is ever made
   executable.
3. **Verification does not depend on the network.** Not on TLS holding, not on
   the CDN being honest, not on the release being untampered — only on this
   repository's history, which is public and reviewable.
4. **Authenticity of published assets.** Every release asset is signed with
   Sigstore cosign in keyless mode, and the certificate is in the public Rekor
   transparency log. There is no private signing key anywhere.
5. **It touches no secrets.** Nothing here reads a keystore, prompts for a
   passphrase, stores a credential, or authenticates to anything.

**What it does not guarantee**

1. **Nothing about the binary's behaviour.** This repository attests to the
   *identity* of the bytes, not to their correctness or safety. The CLI is
   built from `basis-core`, which is not public; its defects — including the
   four documented in the README — are outside this boundary.
2. **No protection against a compromised maintainer account.** Someone who can
   push to `main` can commit a checksum that matches a malicious binary. That
   is detectable in a public diff, not prevented. It is this project's main
   residual risk and is stated as such.
3. **No availability guarantee.** If GitHub is down, or a release is deleted,
   this tool cannot get you anything. It will say so rather than improvise.
4. **Nothing about the network the CLI talks to.** LITHOS has no value, the
   devnet may be reset, and no key used against it should be treated as
   valuable.

## Scope

This tool talks to a **development network**. LITHOS has no value and the chain
may be reset without notice. Treat any key you use against it as a test key,
and never reuse a passphrase you use elsewhere.

Reports about the network itself, the RPC gateway or the explorer are in scope
for the same address, even though the code for those does not live here.
