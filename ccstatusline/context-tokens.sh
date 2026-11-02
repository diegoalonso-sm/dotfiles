#!/usr/bin/env bash
# Contexto usado sobre el total, en tokens: "76k/200k 38%". Lee el JSON de Claude Code por stdin.
# Sin colores propios: usa los del widget. Sin datos: no imprime nada.
set -uo pipefail

jq -r '
  def fmt: if . >= 1000000 then ((. / 100000 | floor) / 10 | tostring) + "M"
           elif . >= 1000 then ((. / 1000 | round | tostring) + "k")
           else tostring end;
  .context_window as $c
  | ($c.context_window_size // empty) as $total
  | ($c.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $usado
  | (if ($usado > 0) then $usado else (($c.used_percentage // 0) * $total / 100 | round) end) as $n
  | "\($n | fmt)/\($total | fmt) \(($n * 100 / $total) | round)%"
'
