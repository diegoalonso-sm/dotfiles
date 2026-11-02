#!/usr/bin/env bash
# Barra de uso del plan para ccstatusline (widget custom-command con preserveColors).
# Lee el JSON de Claude Code por stdin. Uso: usage-bars.sh 5h|7d
# Verde < 70 %, amarillo 70-89 %, rojo >= 90 %. Sin datos de límite: no imprime nada.
set -uo pipefail

ventana="${1:-5h}"
case "$ventana" in
  5h) clave="five_hour"; etiqueta="├─▸ 5h"; fmt="%H:%M" ;;
  7d) clave="seven_day"; etiqueta="╰─▸ 7d"; fmt="%a %d" ;;
  *)  exit 0 ;;
esac

IFS=$'\t' read -r pct reset < <(jq -r --arg k "$clave" \
  '.rate_limits[$k] // empty | [(.used_percentage // empty), (.resets_at // "")] | @tsv')
[ -n "${pct:-}" ] || exit 0

entero=$(printf '%.0f' "$pct")
if   [ "$entero" -ge 90 ]; then color='38;2;247;118;142'   # rojo
elif [ "$entero" -ge 70 ]; then color='38;2;224;175;104'   # amarillo
else                            color='38;2;158;206;106'   # verde
fi

ancho=10
llenas=$(( (entero * ancho + 50) / 100 )); [ "$llenas" -gt "$ancho" ] && llenas=$ancho
barra_llena=""; barra_vacia=""
for ((i = 0; i < llenas; i++)); do barra_llena+="█"; done
for ((i = llenas; i < ancho; i++)); do barra_vacia+="░"; done

hora=""
[ -n "$reset" ] && hora=" ↻ $(date -d "@$reset" +"$fmt" 2>/dev/null)"

printf '\033[%sm%s %s\033[2m%s\033[22m %3d%%\033[0m%s' \
  "$color" "$etiqueta" "$barra_llena" "$barra_vacia" "$entero" "$hora"
