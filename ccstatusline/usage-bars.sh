#!/usr/bin/env bash
# Barra de uso del plan para ccstatusline (widget custom-command con preserveColors).
# Lee el JSON de Claude Code por stdin. Uso: usage-bars.sh 5h|7d|rama
# "rama" imprime solo la sangría y la esquina de la última rama (la del agente).
# Verde < 70 %, amarillo 70-89 %, rojo >= 90 %. Sin datos de límite: no imprime nada.
# A la izquierda va el correo de la cuenta de Claude; las dos barras salen de él en forma de árbol:
#   󰀉 correo ─┬╴5h ...
#            ├╴7d ...
#            ╰╴agente (modelo, esfuerzo, contexto, duración)
set -uo pipefail

ventana="${1:-5h}"
gris='38;2;86;95;137'   # parte vacía y ramas del árbol: gris azulado fijo

# Correo de la cuenta (oauthAccount.emailAddress en .claude.json, o en CLAUDE_CONFIG_DIR).
correo=$(jq -r '.oauthAccount.emailAddress // empty' "${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json" 2>/dev/null)
correo="${correo:-no account}"
# Ícono, espacio, correo, espacio y "─" ocupan ${#correo}+4 columnas; ahí caen las ramas.
# ccstatusline recorta los espacios al inicio de la salida; el código de color previo lo evita.
rama() { printf '\033[%sm%*s%s' "$gris" $(( ${#correo} + 4 )) '' "$1"; }

if [ "$ventana" = rama ]; then
  rama '╰╴'; printf '\033[0m'
  exit 0
fi
case "$ventana" in
  5h) clave="five_hour"; etiqueta="5h" ;;
  7d) clave="seven_day"; etiqueta="7d" ;;
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

ancho=25
llenas=$(( (entero * ancho + 50) / 100 )); [ "$llenas" -gt "$ancho" ] && llenas=$ancho
barra_llena=""; barra_vacia=""
for ((i = 0; i < llenas; i++)); do barra_llena+="●"; done
for ((i = llenas; i < ancho; i++)); do barra_vacia+="○"; done

hora=""
if [ -n "$reset" ]; then
  falta=$(( reset - $(date +%s) )); [ "$falta" -lt 0 ] && falta=0
  if   [ "$falta" -ge 86400 ]; then resta="$((falta / 86400))d $(( falta % 86400 / 3600 ))h"
  elif [ "$falta" -ge 3600 ];  then resta="$((falta / 3600))h $(printf '%02d' $(( falta % 3600 / 60 )))m"
  else                              resta="$(( falta / 60 ))m"
  fi
  hora=", resets in $resta"
fi

if [ "$ventana" = 5h ]; then
  prefijo=$(printf '\033[38;2;192;202;245m%s %s \033[%sm─┬╴' $'\U000F0009' "$correo" "$gris")
else
  prefijo=$(rama '├╴')
fi
printf '%s\033[%sm%s %s\033[%sm%s\033[%sm %s\033[0m%s' \
  "$prefijo" "$color" "$etiqueta" "$barra_llena" "$gris" "$barra_vacia" "$color" "${entero}% used" "$hora"
