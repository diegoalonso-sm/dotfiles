#!/usr/bin/env bash
# Instala claude-statusline y lo activa en Claude Code (usuario actual).
set -euo pipefail

VERSION="${CLAUDE_STATUSLINE_VERSION:-0.11.0}"
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
SETTINGS="$HOME/.claude/settings.json"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  destino="linux_amd64" ;;
  Linux-aarch64) destino="linux_arm64" ;;
  Darwin-x86_64) destino="darwin_amd64" ;;
  Darwin-arm64)  destino="darwin_arm64" ;;
  *) echo "Plataforma no soportada: $(uname -sm)" >&2; exit 1 ;;
esac

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
base="https://github.com/felipeelias/claude-statusline/releases/download/v${VERSION}"
archivo="claude-statusline_${VERSION}_${destino}.tar.gz"

curl -fsSL "$base/$archivo" -o "$tmp/$archivo"
curl -fsSL "$base/checksums.txt" -o "$tmp/checksums.txt"
(cd "$tmp" && grep " $archivo\$" checksums.txt | sha256sum -c -)

mkdir -p "$BIN" "$HOME/.config/claude-statusline" "$HOME/.claude"
tar -xzf "$tmp/$archivo" -C "$tmp" claude-statusline
install -m 0755 "$tmp/claude-statusline" "$BIN/claude-statusline"
cp "$AQUI/claude-statusline/config.toml" "$HOME/.config/claude-statusline/config.toml"

# Mezcla solo la clave statusLine; el resto de settings.json no se toca.
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
python3 - "$SETTINGS" <<'PY'
import json, sys
ruta = sys.argv[1]
with open(ruta) as f:
    datos = json.load(f)
datos["statusLine"] = {"type": "command", "command": "claude-statusline prompt"}
with open(ruta, "w") as f:
    json.dump(datos, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "Listo. Asegúrate de que $BIN esté en el PATH y reinicia Claude Code."
