#!/usr/bin/env bash
# Nivel de esfuerzo con color según intensidad. Lee el JSON de Claude Code por stdin.
# Fuente: effort.level del JSON; si no viene, effortLevel de ~/.claude/settings.json.
# low verde, medium amarillo, high naranja, xhigh y max rojo; otro valor en morado.
set -uo pipefail

nivel=$(jq -r '.effort.level // empty' 2>/dev/null)
[ -n "$nivel" ] || nivel=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
nivel="${nivel:-default}"

case "$nivel" in
  low)       color='38;2;158;206;106' ;;
  medium)    color='38;2;224;175;104' ;;
  high)      color='38;2;255;158;100' ;;
  xhigh|max) color='38;2;247;118;142' ;;
  *)         color='38;2;157;124;216' ;;
esac
printf '\033[%sm󰧑 %s\033[0m' "$color" "$nivel"
