# src/ — código fuente del CLI

**Esta carpeta está vacía a propósito.** Aquí va `basis-core`, el workspace de
Rust del que salen `basis` y `basis-node`. Está clonado en
`../../core` (repo `bitbucket.org/base-computing/basis-core`).

**Cuidado con la rama.** `master` es un andamio de cuatro commits con un
`lib.rs` que solo imprime «Basis Core Initialized»; el código real está en otras
ramas, unas 170. La que corresponde al despliegue es
**`origin/deploy/mvp-single-node`**, con 18 crates: `basis-cli`, `basis-crypto`,
`basis-evm`, `basis-kernel`, `basis-mempool`, `basis-net`, `basis-node`,
`basis-prover`, `basis-rpc`, `basis-runtime`, `basis-sdk-rust`,
`basis-sdk-wasm`, `basis-store`, `basis-wire`, y algunos más.

Para mirar sin cambiar de rama:

```bash
git show "origin/deploy/mvp-single-node:crates/basis-crypto/src/scheme.rs"
```

Nota de zsh: usa `"${B}:ruta"` y no `"$B:ruta"`, porque `:c` se interpreta como
modificador de historial y se come parte de la ruta.

## Compilar

```bash
git -C ../../core checkout deploy/mvp-single-node
cargo build --release --locked \
  -p basis-node --bin basis-node \
  -p basis-cli  --bin basis
```

Los binarios que corren en la devnet salieron de `f74b78e` con `rustc` 1.96.1,
dentro de `rust:1.96-bookworm`. La infraestructura espera el repo en
`~/workspace/basis-core` (`BASIS_CORE_REPO` en `infrastructure/scripts/config.sh`).

## Lo que ya se sacó de ahí

Todo lo que le faltaba a la cartera, y está implementado y probado en
`../../wallet`:

| Qué | Dónde estaba |
|---|---|
| Preimagen de firma: `BLAKE3("basis:tx:v1" ‖ payload)` | `basis-crypto/src/scheme.rs` (`TX_SIGN_DOMAIN`) y `basis-wire/src/hash.rs` (`domain_hash`) |
| La tubería canónica de ocho pasos, documentada | cabecera de `basis-sdk-wasm/src/signing.rs` |
| Keystore: Argon2id 19456/2/1 + AES-256-GCM con `aad = pubkey ‖ 0x02` | `basis-crypto/src/keystore/encrypted.rs` |
| `accountId = BLAKE3(publicKey)` | `basis-kernel/src/shared_security/types.rs` |

Con eso, `@basis/js` firma en JavaScript puro y no necesita compilar
`basis-sdk-wasm`.
