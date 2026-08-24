# Governance

Short, because the project is small and pretending otherwise would be worse
than saying so.

## Who decides

**Sebastián Quintero** ([@sebastian-quintero-osorio](https://github.com/sebastian-quintero-osorio))
is the maintainer and has final say on what is merged, released and documented
here. He is also the security contact and the person responsible for licence
compliance.

There is currently **one maintainer**. That is a real limitation, stated rather
than hidden: it means a single point of failure for reviews, releases and
response times. Adding maintainers is on the list, and the section below says
how that happens.

## How decisions get made

- **Documentation and script changes** — pull request, reviewed and merged by
  the maintainer.
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
invitation from an existing maintainer. There is no committee and no vote,
because with one maintainer a vote would be theatre.

## Releases

Releases are tagged `vX.Y.Z` and published as GitHub releases with the binaries
attached. `checksums/<tag>/` is committed **before** the release is published,
and CI verifies the published assets against it and signs them. A release whose
binaries do not match the committed checksums fails visibly.

## Changing this document

Pull request, like anything else.
