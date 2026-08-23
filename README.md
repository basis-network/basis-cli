# basis-cli

El cliente de línea de comandos de Basis Network: crea carteras, consulta la
cadena, transfiere LITHOS y despliega contratos. Es **la única herramienta que
hoy sabe firmar** para esta red, porque Basis firma con ML-DSA-65 (FIPS 204) y
ninguna cartera de Ethereum puede hacerlo.

Esta carpeta tiene dos mitades y hace falta entender por qué:

| Carpeta | Qué guarda | Estado |
|---|---|---|
| [`bin/`](./bin) | Los `SHA256SUMS` por plataforma | Los ejecutables se descargan — ver abajo |
| [`src/`](./src) | El código fuente (`basis-core`) | **Vacío** — ver `src/README.md` |

---

## Los binarios

Los ejecutables **no están en este repositorio**: son 52 MB por versión y git
no olvida, así que diez versiones serían medio giga de historia y sacarlos
después obligaría a reescribirla. Viven en un bucket de Cloud Storage:

```
gs://basis-releases/cli/2026-08-20/
├── linux-x86_64/     basis · basis-node · SHA256SUMS
└── windows-x86_64/   basis.exe · basis-node.exe · SHA256SUMS
```

Lo que **sí** está versionado aquí son los `SHA256SUMS`. Esa es toda la idea:
la suma viaja por un canal que se revisa —commits, revisiones, historia— y el
binario por otro. Si alguien altera lo que hay en el bucket, `sha256sum -c`
contra la copia de este repositorio lo delata.

```bash
./descargar.sh linux-x86_64      # baja y verifica en un paso
```

o a mano:

```bash
gcloud storage cp -r gs://basis-releases/cli/2026-08-20/linux-x86_64 bin/
cd bin/linux-x86_64 && sha256sum -c SHA256SUMS
```

El bucket es privado: hace falta acceso al proyecto `basis-devnet`. Publicarlo
es una decisión aparte, y la red todavía no está lanzada.

**Linux** — compilados por el equipo el 2026-08-20 desde `basis-core` `f74b78e`
con `rustc` 1.96.1, dentro de `rust:1.96-bookworm` (Debian 12, glibc 2.36) para
que corran tal cual en la imagen `debian-12` de Compute Engine. Enlazan
únicamente `libc`, `libm` y `libgcc_s`: ningún `libssl`, porque el workspace pasó
a rustls. Es la pareja que corre hoy en la devnet.

**Windows** — vienen del `basis-network-pilot-kit`. Son builds de prueba; el
objetivo de producción es Linux. No hay constancia de con qué commit se
compilaron.

**No hay binario de macOS.** Es el hueco más visible para terceros: medio equipo
de cualquier empresa trabaja ahí.

## Qué hace

```
basis wallet new|import          Cartera ML-DSA-65 (keystore cifrado)
basis validator-key new|import   Claves de validador
basis balance|nonce|block        Consultas de estado
basis tx-receipt                 Recibo de una transacción
basis send tx                    Transferir, llamar un contrato o desplegarlo
```

El endpoint se pasa con `--rpc-url` o con la variable `BASIS_RPC_URL`.

## Cosas verificadas que conviene saber antes de usarlo

Todo lo de abajo está medido contra la devnet, no supuesto.

**Las consultas piden 20 bytes; las cuentas tienen 32.** Una cuenta de Basis es
`BLAKE3(clave pública ML-DSA-65)`, 32 bytes, y es lo que imprime `wallet new`.
Pero `balance`, `nonce` y `tx-receipt` exigen 40 caracteres hex y hay que pasarles
los **últimos** 20 bytes de esa identidad:

```
identidad   0x0ad5fa7d057384f38e4b3c81f68af934d5547d6e2214f44d56dc0077aec217f6
para balance            0xf68af934d5547d6e2214f44d56dc0077aec217f6
```

Con los primeros 20 no da error: responde `balance 0`, que parece una cuenta
vacía. `--to` de `send tx` sí acepta la forma completa de 32 bytes.

**Imprime las unidades mal.** Muestra `4985159985308 wei (0.000005
eth-equivalent)`: la unidad es el **tomo**, la moneda es **LITHOS**, y
1 LITHOS = 10⁹ tomos (no 10¹⁸, que es lo que el CLI supone al dividir).

**No sabe enviar cabeceras HTTP.** No hay `--rpc-token` ni forma de mandar
`Authorization: Bearer`, y de ahí que el acceso de terceros pase por un gateway
que lleva el token en la ruta (`/rpc/<token>`).

**Lleva sus propias raíces TLS.** Usa rustls con raíces empotradas y no lee el
almacén de certificados del sistema: `SSL_CERT_FILE` no le afecta y no acepta
`--cacert` ni `--insecure`. Detrás de una inspección TLS corporativa —un
FortiGate, un Zscaler— falla todo HTTPS con `send: error sending request`. El
rodeo es un proxy local en HTTP que reenvíe al nodo.

## Formato de transacción

El CLI firma con ML-DSA-65 y envía por `eth_sendRawTransaction`. La serialización
está documentada byte a byte en
[`../wallet/docs/FORMATO-TRANSACCION.md`](../wallet/docs/FORMATO-TRANSACCION.md),
deducida por captura y validada contra el decodificador del nodo.

## De dónde salieron estas copias

Se copiaron, no se movieron: `basis-linux-devnet-2026-08-20/bin/` y
`basis-network-pilot-kit/bin/` siguen intactos porque son entregas fechadas y el
pilot kit no funciona sin los suyos. Esta carpeta es el sitio **canónico** al que
apuntar de ahora en adelante.
