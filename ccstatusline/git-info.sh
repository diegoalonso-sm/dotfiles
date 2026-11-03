#!/usr/bin/env bash
# Datos de git del directorio de la sesión. Lee el JSON de Claude Code por stdin.
# Uso: git-info.sh repo|branch|worktree|upstream|changes
# Sin dato imprime "no repo", "no branch", "no worktree", "no upstream" o "no changes",
# para que el segmento no desaparezca.
#   upstream: commits por subir y por bajar respecto del remoto (↑ adelante, ↓ atrás); "synced" si está al día.
#   changes:  archivos en staging (+), modificados (~) y sin seguimiento (?); "clean" si no hay cambios.
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
    upstream)
      if cuenta=$(git -C "$dir" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then
        read -r atras adelante <<< "$cuenta"
        if [ "$atras" -eq 0 ] && [ "$adelante" -eq 0 ]; then valor="synced"
        else
          partes=()
          [ "$adelante" -gt 0 ] && partes+=("↑$adelante")
          [ "$atras" -gt 0 ] && partes+=("↓$atras")
          valor="${partes[*]}"
        fi
      fi
      ;;
    changes)
      estado=$(git -C "$dir" status --porcelain 2>/dev/null)
      if [ -z "$estado" ]; then
        valor="clean"
      else
        staged=$(grep -c '^[MADRC]' <<< "$estado")
        modif=$(grep -c '^.[MD]' <<< "$estado")
        nuevos=$(grep -c '^??' <<< "$estado")
        partes=()
        [ "$staged" -gt 0 ] && partes+=("+$staged")
        [ "$modif" -gt 0 ] && partes+=("~$modif")
        [ "$nuevos" -gt 0 ] && partes+=("?$nuevos")
        valor="${partes[*]}"
      fi
      ;;
  esac
fi

printf '%s' "${valor:-no $campo}"
