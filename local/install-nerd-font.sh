#!/usr/bin/env bash
# Instala JetBrainsMono Nerd Font en el equipo LOCAL (donde corre Zed), no en el contenedor.
# Necesaria para las flechas powerline de la statusline.
set -euo pipefail

VERSION="${NERD_FONTS_VERSION:-3.5.1}"
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${VERSION}/JetBrainsMono.tar.xz"

case "$(uname -s)" in
  Darwin) destino="$HOME/Library/Fonts" ;;
  Linux)  destino="$HOME/.local/share/fonts/JetBrainsMonoNerd" ;;
  *) echo "Sistema no soportado: $(uname -s)" >&2; exit 1 ;;
esac

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp/font.tar.xz"
mkdir -p "$destino"
tar -xJf "$tmp/font.tar.xz" -C "$destino" --wildcards '*.ttf'
[ "$(uname -s)" = Linux ] && fc-cache -f "$destino"

cat <<'MSG'
Fuente instalada. Falta una línea en el settings.json LOCAL de Zed
(Zed: Open Settings), junto a la de port_forwards:

  "terminal": { "font_family": "JetBrainsMono Nerd Font" }

Luego reinicia Zed.
MSG
