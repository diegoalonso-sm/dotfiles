#!/usr/bin/env bash
# Datos de git del directorio de la sesión. Lee el JSON de Claude Code por stdin.
# Uso: git-info.sh dir|repo|branch|worktree|upstream|changes|pr
#   dir:  directorio de la sesión, con ~ en vez del home (dentro o fuera de un repo).
#   repo: nombre del repo (más la subcarpeta si corresponde); fuera de un repo, el directorio.
# Sin dato imprime "no repo", "no branch", "no worktree", "no upstream", "no changes" o "no PR",
# para que el segmento no desaparezca.
#   upstream: commits por subir (↑) y por bajar (↓) respecto del remoto, siempre los dos.
#   changes:  archivos en staging (+), modificados (~) y sin seguimiento (?).
#   pr:       número del PR abierto de la rama, vía gh. Se guarda en caché 2 minutos y se
#             actualiza en segundo plano para no frenar la barra.
set -uo pipefail

campo="${1:-branch}"
dir=$(jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)

if [ "$campo" = "dir" ]; then
  printf '%s' "${dir:+${dir/#$HOME/\~}}"
  [ -n "$dir" ] || printf 'no dir'
  exit 0
fi
valor=""

if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  raiz=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
  case "$campo" in
    repo)
      # En un worktree, el repo es el del checkout principal, no el del worktree.
      comun=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
      valor=$(basename "$(dirname "$comun")")
      # Si la sesión está en una subcarpeta, se agrega la ruta dentro del repo.
      sub=$(git -C "$dir" rev-parse --show-prefix 2>/dev/null); sub="${sub%/}"
      [ -n "$sub" ] && valor="$valor/$sub"
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
        valor="↑$adelante ↓$atras"
      fi
      ;;
    changes)
      estado=$(git -C "$dir" status --porcelain 2>/dev/null)
      if [ -n "$estado" ]; then
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
    pr)
      rama=$(git -C "$dir" branch --show-current 2>/dev/null)
      if [ -n "$rama" ] && command -v gh >/dev/null; then
        cache="${XDG_CACHE_HOME:-$HOME/.cache}/ccstatusline/pr-$(printf '%s' "$raiz:$rama" | md5sum | cut -c1-16)"
        mkdir -p "$(dirname "$cache")"
        edad=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
        if [ "$edad" -ge 120 ]; then
          touch "$cache"   # evita lanzar varias consultas mientras la primera corre
          ( cd "$dir" && gh pr view --json number,state \
              -q 'select(.state == "OPEN") | "PR #\(.number)"' > "$cache.tmp" 2>/dev/null
            mv -f "$cache.tmp" "$cache" ) >/dev/null 2>&1 &
        fi
        valor=$(cat "$cache" 2>/dev/null)
      fi
      campo="PR"
      ;;
  esac
fi
[ "$campo" = "pr" ] && campo="PR"
# Fuera de un repo, el segmento del repo muestra el directorio, con ~ en vez del home.
if [ "$campo" = "repo" ] && [ -z "$valor" ] && [ -n "$dir" ]; then
  valor="${dir/#$HOME/\~}"
fi

printf '%s' "${valor:-no $campo}"
