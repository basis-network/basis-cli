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
