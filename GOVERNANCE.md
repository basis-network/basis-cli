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

## The roles, and who holds them

| Role | Held by | Responsible for |
|---|---|---|
| **Lead maintainer** | Sebastian Tobar Quintero | Final say on what is merged, released and documented. Breaking ties. Keeping this document true |
| **Maintainer** | Sebastian Tobar Quintero, David Alejandro Blandón Román | Reviewing and merging pull requests; committing `checksums/<tag>/` before a release is published; publishing releases; triaging issues |
| **Security contact** | Sebastian Tobar Quintero | Reading the private advisory queue and `security@basisnetwork.com.co`; acknowledging within 3 working days; running the process in [SECURITY.md](./SECURITY.md#reporting-a-vulnerability) to disclosure |
| **Licence compliance** | Sebastian Tobar Quintero | That every file carries its copyright and licence, and that `reuse lint` stays green |
| **Organisation owner** | Sebastian Tobar Quintero, David Alejandro Blandón Román | Access to the GitHub organisation, its settings and its secrets. Either can restore the other's access |
| **Release signing** | *nobody* | Deliberately: signing is keyless, performed by `release.yml` under its own OIDC identity. There is no key for a person to hold, lose, or be coerced into using |

Both maintainers have identical repository and organisation access. The lead
maintainer role is about who decides, not about who can act.

Two-factor authentication is **required** for every member of the organisation,
so repository write access and the private vulnerability queue both sit behind
it.

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
