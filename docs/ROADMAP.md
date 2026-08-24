# Roadmap

What this project intends to do, and what it intends not to do. Reviewed when
something on it moves; last reviewed **2026-08-24**.

A roadmap is not a promise. It is here so that someone deciding whether to
depend on this tool can see where it is going before they find out the hard
way.

## What this repository controls, and what it does not

This repository distributes and verifies the CLI. **It does not build it** —
the binary comes from `basis-core`, which is not public. So the list below is
in two halves, and the split is not cosmetic: the first half we can schedule,
the second we can only report.

## Next twelve months — in this repository

| | What | Why it matters |
|---|---|---|
| 1 | **A macOS build in the release matrix** | The most visible gap. `download.sh` already handles `shasum`, so the client side is ready; what is missing is a published asset. Blocked on a build host, not on design. |
| 2 | **Signed version tags** | Assets are signed today; the tags they come from are not. Closes the gap between "this binary was published by our workflow" and "this tag is the one the maintainers made". |
| 3 | **Recording provenance for every platform** | The Linux build names its source commit and toolchain; the Windows one does not, because it predates the practice. No new asset ships without it. |
| 4 | **Branch coverage, if a FLOSS tool for shell appears** | Statement coverage is measured and enforced at 90%. Nothing measures branch coverage for bash today; if that changes, it goes in CI the same way. |
| 5 | **Keeping the four documented rough edges accurate** | They are in the README because they cost an afternoon each. As `basis-core` fixes them, they move to CHANGELOG and out of the README — not silently. |

## Next twelve months — reported, not scheduled

These are defects in the CLI itself. They are documented in the README under
*Things worth knowing before you use it*, they have been raised with the team
that maintains `basis-core`, and **this repository cannot fix them**:

- queries take the last 20 bytes of a 32-byte account, and the wrong 20 answer
  `balance 0` instead of failing;
- printed units are wrong — the unit is the tomo, 1 LITHOS = 10⁹ tomos;
- no way to send an HTTP header, so no `Authorization: Bearer`;
- TLS roots are embedded, so corporate TLS inspection breaks every HTTPS call.

When one is fixed upstream, the release notes here will say so.

## What this project will not do

Stated plainly, because a roadmap that only lists ambitions is half a
document:

- **No long-term support branches.** Only the latest release is supported.
  This tracks a development network that may be reset without notice; pinning
  an old client to a chain that no longer exists helps nobody.
- **No CLI source here.** Patches to the CLI's behaviour cannot be accepted in
  this repository. That does not change until `basis-core` is public, and that
  decision is not made here.
- **No binaries in git.** They stay attached to releases and the checksums stay
  in git. That separation is the reason this repository exists — see
  [ARCHITECTURE.md](./ARCHITECTURE.md).
- **No package-manager distribution yet** (Homebrew, apt, winget). Each one is
  a second channel that has to be kept honest, and there is one maintainer
  writing them. Not before macOS ships.
- **No bug bounty.** Reports are read and credited; there is no money behind
  it, and saying otherwise would be a lie with a budget attached.

## Beyond a year

Nothing on this list is scheduled, and it is here to be honest about the
direction rather than to imply commitment: opening `basis-core`, which would
make most of the "reported, not scheduled" section obsolete; reproducible
builds for the published binaries; and a second active maintainer reviewing
changes, which is the one thing that would move this project's remaining
open-source-maturity gaps — see [GOVERNANCE.md](../GOVERNANCE.md) for what
having two maintainers buys today and what it does not.
