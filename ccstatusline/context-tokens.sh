#!/usr/bin/env bash
# Contexto usado como medidor de 10 puntos más el porcentaje: "●●●●○○○○○○ 38%".
# Lee el JSON de Claude Code por stdin. Verde < 70 %, amarillo 70-89 %, rojo >= 90 %.
# Sin datos imprime "no context", como "no repo" o "no branch".
set -uo pipefail

pct=$(jq -r '
  .context_window as $c
  | ($c.context_window_size // empty) as $total
  | ($c.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $usado
  | (if ($usado > 0) then ($usado * 100 / $total) else ($c.used_percentage // 0) end)
  | round
' 2>/dev/null)

icono='󰊚'
if [ -z "$pct" ]; then
  printf '\033[38;2;158;206;106m%s no context\033[0m' "$icono"
  exit 0
fi

if   [ "$pct" -ge 90 ]; then color='38;2;247;118;142'
elif [ "$pct" -ge 70 ]; then color='38;2;224;175;104'
else                         color='38;2;158;206;106'
fi
gris='38;2;86;95;137'
llenas=$(( (pct * 10 + 50) / 100 )); [ "$llenas" -gt 10 ] && llenas=10
llena=""; vacia=""
for ((i = 0; i < llenas; i++)); do llena+="●"; done
for ((i = llenas; i < 10; i++)); do vacia+="○"; done
printf '\033[%sm%s %s\033[%sm%s\033[%sm %s%%\033[0m' "$color" "$icono" "$llena" "$gris" "$vacia" "$color" "$pct"
