#!/usr/bin/env bash
# Instala ccstatusline (con Bun, sin root ni Node) y lo activa en Claude Code.
# Idempotente. Probado en Linux x86_64 sin AVX (Bun baseline).
set -euo pipefail

BUN_VERSION="${BUN_VERSION:-1.4.4}"
CCS_VERSION="${CCSTATUSLINE_VERSION:-2.2.33}"
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
export BUN_INSTALL="$HOME/.local/bun"
SETTINGS="$HOME/.claude/settings.json"
CONFIG="$HOME/.config/ccstatusline"

command -v jq >/dev/null || { echo "Falta jq (lo usa usage-bars.sh)." >&2; exit 1; }

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  zip="bun-linux-x64-baseline" ;;
  Linux-aarch64) zip="bun-linux-aarch64" ;;
  Darwin-arm64)  zip="bun-darwin-aarch64" ;;
  Darwin-x86_64) zip="bun-darwin-x64" ;;
  *) echo "Plataforma no soportada: $(uname -sm)" >&2; exit 1 ;;
esac

mkdir -p "$BIN" "$CONFIG" "$HOME/.claude"

if ! "$BIN/bun" --version 2>/dev/null | grep -qx "$BUN_VERSION"; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  base="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}"
  curl -fsSL "$base/$zip.zip" -o "$tmp/$zip.zip"
  curl -fsSL "$base/SHASUMS256.txt" -o "$tmp/sums.txt"
  (cd "$tmp" && grep " $zip.zip\$" sums.txt | sha256sum -c -)
  unzip -q "$tmp/$zip.zip" -d "$tmp"
  install -m 0755 "$tmp/$zip/bun" "$BIN/bun"
fi

"$BIN/bun" add -g "ccstatusline@${CCS_VERSION}" >/dev/null

# El binario de ccstatusline usa "#!/usr/bin/env node"; se ejecuta con Bun.
cat > "$BIN/ccstatusline" <<WRAP
#!/usr/bin/env bash
exec "$BIN/bun" "$BUN_INSTALL/install/global/node_modules/ccstatusline/dist/ccstatusline.js" "\$@"
WRAP
chmod +x "$BIN/ccstatusline"

cp "$AQUI/ccstatusline/settings.json" "$CONFIG/settings.json"
install -m 0755 "$AQUI/ccstatusline/usage-bars.sh" "$CONFIG/usage-bars.sh"
install -m 0755 "$AQUI/ccstatusline/context-tokens.sh" "$CONFIG/context-tokens.sh"

# Mezcla solo la clave statusLine; el resto de settings.json no se toca.
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
python3 - "$SETTINGS" "$BIN/ccstatusline" <<'PY'
import json, sys
ruta, comando = sys.argv[1], sys.argv[2]
with open(ruta) as f:
    datos = json.load(f)
datos["statusLine"] = {"type": "command", "command": comando}
with open(ruta, "w") as f:
    json.dump(datos, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "Listo. Reinicia Claude Code. Vista previa: echo '{}' | $BIN/ccstatusline"
