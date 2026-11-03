#!/usr/bin/env bash
# Correo de la cuenta de Claude con la que corre la sesión, sobre las barras de cuota.
# Se lee de .claude.json (oauthAccount.emailAddress), en CLAUDE_CONFIG_DIR si está definido.
# Sin dato imprime "no account".
set -uo pipefail

archivo="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
correo=$(jq -r '.oauthAccount.emailAddress // empty' "$archivo" 2>/dev/null)
printf '\033[38;2;86;95;137m╭╴\033[38;2;192;202;245m%s %s\033[0m' $'\U000F0009' "${correo:-no account}"
