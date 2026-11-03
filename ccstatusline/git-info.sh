#!/usr/bin/env bash
# Datos de git del directorio de la sesión. Lee el JSON de Claude Code por stdin.
# Uso: git-info.sh repo|branch|worktree
# Sin dato imprime "no repo", "no branch" o "no worktree", para que el segmento no desaparezca.
set -uo pipefail

campo="${1:-branch}"
dir=$(jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
valor=""

if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  raiz=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
  case "$campo" in
    repo)
      # En un worktree, el repo es el del checkout principal, no el del worktree.
      comun=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
      valor=$(basename "$(dirname "$comun")")
      ;;
    branch)
      valor=$(git -C "$dir" branch --show-current 2>/dev/null)
      [ -n "$valor" ] || valor=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
      ;;
    worktree)
      gitdir=$(git -C "$dir" rev-parse --path-format=absolute --git-dir 2>/dev/null)
      comun=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
      [ "$gitdir" != "$comun" ] && valor=$(basename "$raiz")
      ;;
  esac
fi

printf '%s' "${valor:-no $campo}"
