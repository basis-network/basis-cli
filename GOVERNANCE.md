# Governance

Short, because the project is small and pretending otherwise would be worse
than saying so.

## Who decides

**Sebastian Tobar Quintero** ([@sebastian-quintero-osorio](https://github.com/sebastian-quintero-osorio))
is the lead maintainer and has final say on what is merged, released and
documented here. He is also the security contact and the person responsible for
licence compliance.

**David Alejandro Blandón Román**
([@DavidAquiles](https://github.com/DavidAquiles)) is the second maintainer,
with the same access: owner of the organisation, able to merge and able to
publish a release. That is the whole point of the role — the project does not
stop, and nothing becomes unreachable, if one person is not available.

**Two maintainers**, and it is worth being exact about what that buys and what
it does not. It removes the single point of failure for access, for releases
and for a vulnerability report going unread. It does not yet mean every change
gets a second pair of eyes: with two people, requiring each to review the other
would stall the project the first time either one is away. Changes still land
through pull requests, and a second review happens when it can rather than
being promised and skipped.

## How decisions get made

- **Documentation and script changes** — pull request, reviewed and merged by
  a maintainer.
- **Anything that changes what this repository vouches for** — for example
  dropping a binary from distribution, or changing how checksums are anchored —
  goes in the CHANGELOG under its own heading, with the reasoning, whether or
  not anyone asked.
- **The CLI's own behaviour** is not decided here. It is built from
  `basis-core`, which is not public. Issues raised here reach that team; the
  decision is theirs.

## Becoming a maintainer

By sustained contribution — issues that turn out to be right, reviews that
catch things, documentation that survives contact with readers — and then by
invitation, which both maintainers have to agree on. There is no committee and
no vote: with two people a vote is either unanimous or deadlocked, and neither
is a decision procedure worth writing down.

## Releases

Releases are tagged `vX.Y.Z` and published as GitHub releases with the binaries
attached. `checksums/<tag>/` is committed **before** the release is published,
and CI verifies the published assets against it and signs them. A release whose
binaries do not match the committed checksums fails visibly.

## Changing this document

Pull request, like anything else.
