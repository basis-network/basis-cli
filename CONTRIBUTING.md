# Contributing

Thank you for looking. Please read this first — what this repository accepts is
narrower than most, and it is better to know before you write anything.

## What this repository is

It distributes and documents the Basis CLI. It holds the checksums, the
download script and the operational notes. **It does not hold the source code
of the CLI**, which is built from `basis-core`, a repository that is not public
yet.

So:

| Welcome | Not possible here |
|---|---|
| Bug reports about the CLI's behaviour | Patches to the CLI itself |
| Corrections and additions to the docs | New CLI features |
| Fixes to `download.sh` | |
| Reports that a checksum does not match | |

A bug report against the CLI is genuinely useful even though the fix lands
somewhere you cannot see: it reaches the people who maintain `basis-core`.

## Reporting a bug

Open an issue. The template asks for the version, the platform and what you
ran, because the four known rough edges — address length, printed units, HTTP
headers, TLS roots — account for most surprises and the template rules them out
quickly.

**Do not report a security vulnerability in a public issue.** See
[SECURITY.md](./SECURITY.md).

## Making a change

1. Fork, branch, and keep the change small enough to read in one sitting.
2. `make check` must pass — it runs the test suite. CI runs it on every pull
   request.
3. `make lint` must pass: `shellcheck` over both scripts, `reuse lint` over
   every file.
4. Every new file needs an SPDX header, or an entry in `REUSE.toml` if it has
   no comment syntax. `reuse lint` tells you which.
5. Sign off your commits (see below).
6. Open a pull request describing what breaks today and what your change makes
   work.

Comments here explain **why**, not what. If a line needs a comment saying what
it does, the line is the problem.

## Tests

`download.sh` is the only thing here that runs, and it has a suite:

```bash
make check          # or: test/run.sh
```

Each case builds a throwaway release under a temporary directory and points the
script at it over `file://`, so no case touches the network and nothing binary
is committed — the fixtures are made at run time out of strings.

**A change to what `download.sh` does comes with a test.** That is the rule,
and it is not ceremony: this script exists to refuse a download that does not
match the checksum committed here, and a refusal that stops working is silent.
Two of the cases are exactly that path — a tampered binary and a machine with
nothing to hash with — and they are the reason the file exists.

If your change is to a comment or to the docs, no test is needed. If it changes
behaviour, say in the pull request which case covers it.

How much of the script the suite actually reaches is measured, not asserted:

```bash
make coverage       # needs bashcov: gem install bashcov
```

It prints statement coverage for `download.sh` and the exact lines nothing
reached. CI runs it on every pull request and fails below 90%.

## Coding style

The primary language here is **bash**. Contributions follow the
[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html),
with two deliberate differences, both visible throughout the existing code:

- **Comments explain why, not what.** If a line needs a comment saying what it
  does, the line is the problem.
- **Two-space indentation**, which is what the existing scripts use.

The style is enforced by [`shellcheck`](https://www.shellcheck.net/), which
runs in CI over every script and **fails the build**, not just warns. Run it
locally with `make lint`. Where a rule genuinely has to be silenced, the
`# shellcheck disable=` directive goes at the line it applies to, with a
comment saying why — never file-wide.

Other file types: YAML workflows are two-space indented with every action
pinned to a commit SHA, and Markdown wraps at 80 columns.

## How changes are reviewed

Every change lands through a pull request. `main` is protected: no direct
pushes, no force-pushes, linear history, and all CI checks must pass before
merge. Being an administrator does not make an exception acceptable.

A reviewer checks, in this order:

1. **Is it correct?** Does it do what the pull request says, and does the test
   suite still pass?
2. **Does it change behaviour without a test?** If `download.sh` behaves
   differently and no case covers it, that is a blocking comment.
3. **Does it weaken a refusal?** Anything touching the verification path, the
   fail-closed exits, or where the checksum comes from gets read line by line
   against [docs/ASSURANCE-CASE.md](./docs/ASSURANCE-CASE.md). This is the one
   category where "looks fine" is not an acceptable review.
4. **Permissions and pinning.** A workflow change must keep least-privilege
   permissions and SHA-pinned actions.
5. **Licensing.** Every new file carries an SPDX header or a `REUSE.toml`
   entry; `reuse lint` decides, not opinion.
6. **Is the documentation still true?** A change that makes a sentence in the
   README wrong includes the fix for that sentence.

A pull request is acceptable when all CI checks pass and a maintainer other
than the author has approved it. **Today that is not always possible**: the
project has one active maintainer, so some changes are merged by their author
after CI passes. That is a real gap rather than a policy, it is stated in
[GOVERNANCE.md](./GOVERNANCE.md), and it is answered honestly in the project's
OpenSSF Best Practices entry instead of being papered over.

## Good first tasks

Small, self-contained, and genuinely useful — no invented busywork:

- **Test a path the suite does not reach.** `make coverage` prints exactly
  which statements are missed. A case that covers one is a good first pull
  request and needs no knowledge of the network.
- **Try the script on a platform we do not have.** macOS especially: the
  `shasum` fallback exists for it and has never been run there in anger. A bug
  report saying what happened is a contribution.
- **Correct the documentation.** If something in the README did not match what
  you found, that is a defect — see
  [docs/ROADMAP.md](./docs/ROADMAP.md) for what is known and what is not.
- **Improve an error message.** Every failure here should say what went wrong
  and what to do next. Some say only the first half.
- **Check a checksum by hand** against a release and report any mismatch. That
  is the one thing this repository exists for, and an independent check of it
  is worth more than most code.

Issues suitable for a first contribution are labelled
[`good first issue`](https://github.com/basis-network/basis-cli/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

## Sign your work — the DCO

This project uses the [Developer Certificate of Origin](https://developercertificate.org/)
1.1. It is not a copyright assignment and you keep your copyright; it is a
statement that you have the right to contribute the code you are contributing.

Add a `Signed-off-by` line to every commit:

```bash
git commit -s -m "fix: whatever it is"
```

which appends:

```
Signed-off-by: Your Name <your.email@example.com>
```

Use your real name and an address that reaches you. Commits without a sign-off
cannot be merged.

## Licence

Contributions are licensed under [Apache-2.0](./LICENSE), the same as the rest
of the project. By opening a pull request you agree to that.

## Code of Conduct

By participating you agree to the [Code of Conduct](./CODE_OF_CONDUCT.md).
