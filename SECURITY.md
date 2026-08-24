# Security Policy

## Reporting a vulnerability

Email **contact@basisnetwork.com.co** with `[security]` in the subject. Please
do not open a public issue.

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
  --bundle basis-linux-x86_64.cosign.bundle \
  --certificate-identity-regexp \
    'https://github.com/basis-network/basis-cli/.github/workflows/release.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

**v0.1.0 is not signed.** It was published before that workflow existed, and
signing it after the fact from a laptop would produce a signature that attests
to nothing useful. Verify it with the checksum. Releases from v0.1.1 onwards
are signed.

## Keys and keystores

`basis wallet new` writes an encrypted keystore. The passphrase is never
recoverable and is never transmitted. Nothing in this repository — including
`download.sh` — reads a keystore, asks for a passphrase, or touches key
material of any kind.

## Scope

This tool talks to a **development network**. LITHOS has no value and the chain
may be reset without notice. Treat any key you use against it as a test key,
and never reuse a passphrase you use elsewhere.

Reports about the network itself, the RPC gateway or the explorer are in scope
for the same address, even though the code for those does not live here.
