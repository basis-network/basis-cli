# Support

## Something does not work

Read **[Things worth knowing before you use it](./README.md#things-worth-knowing-before-you-use-it)**
first. Four known rough edges account for most of what people hit:

- queries want the **last 20 bytes** of a 32-byte account, and the wrong 20
  answer `balance 0` instead of failing;
- printed units are wrong — the unit is the tomo, 1 LITHOS = 10⁹ tomos;
- there is no way to send an HTTP header, so no `Authorization: Bearer`;
- TLS roots are embedded, so corporate TLS inspection breaks every HTTPS call.

If none of those is it, [open an issue](https://github.com/basis-network/basis-cli/issues).

## Something about the network, not the tool

Endpoints, tokens, chain parameters and how to get test LITHOS are documented
at [basisnetwork.com.co/docs](https://basisnetwork.com.co/docs).

## A security problem

Do not open an issue. See [SECURITY.md](./SECURITY.md).

## Response times

This is maintained by a small team and there is no support contract. Issues are
read; nothing is guaranteed. Security reports are the exception and are
prioritised — see the timelines in SECURITY.md.
