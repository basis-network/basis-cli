#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Baja los ejecutables del bucket y los verifica contra el SHA256SUMS que SÍ
# está versionado en este repositorio.
#
#     ./descargar.sh                 linux-x86_64 (por defecto)
#     ./descargar.sh windows-x86_64
#
# La verificación no es un adorno: la suma viaja por el repositorio y el
# binario por el bucket. Comprobar uno contra el otro es lo único que hace
# que separarlos siga siendo seguro. Si falla, NO uses lo descargado.
# ---------------------------------------------------------------------------
set -euo pipefail

VERSION="${BASIS_CLI_VERSION:-2026-08-20}"
BUCKET="${BASIS_CLI_BUCKET:-gs://basis-releases}"
PLATAFORMA="${1:-linux-x86_64}"

aqui="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
destino="$aqui/bin/$PLATAFORMA"

[ -f "$destino/SHA256SUMS" ] || {
  echo "  ✖ no hay $destino/SHA256SUMS — ¿plataforma correcta?" >&2
  echo "    disponibles: $(cd "$aqui/bin" && ls -d */ | tr -d / | tr '\n' ' ')" >&2
  exit 1
}

echo "==> bajando $PLATAFORMA de $BUCKET/cli/$VERSION"
# Se excluye SHA256SUMS a propósito: el del repositorio es la referencia, y
# sobrescribirlo con el del bucket convertiría la comprobación en un espejo.
for f in $(awk '{print $2}' "$destino/SHA256SUMS"); do
  gcloud storage cp "$BUCKET/cli/$VERSION/$PLATAFORMA/$f" "$destino/$f"
done

echo "==> verificando"
( cd "$destino" && sha256sum -c SHA256SUMS )

chmod +x "$destino"/basis "$destino"/basis-node 2>/dev/null || true
echo "  ✔ en $destino"
