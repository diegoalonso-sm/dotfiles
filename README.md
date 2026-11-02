# dotfiles

Configuración personal de Claude Code y del terminal.

## Statusline: ccstatusline

Tres líneas con tema Tokyo Night, con flechas powerline entre segmentos y esquinas rectas: resumen (modelo, directorio, rama, contexto, costo) y una barra
por cada límite del plan, de 5 horas y semanal. Las barras cambian de color con el uso
(verde < 70 %, amarillo 70-89 %, rojo >= 90 %) y muestran la hora de reinicio.
Las barras vienen del script `ccstatusline/usage-bars.sh`, ya que ccstatusline no tiñe
sus barras por umbral. Si el plan no informa límites, esas dos líneas quedan vacías.

### Contenedor o servidor (donde corre Claude Code)

```bash
git clone <url-de-este-repo> ~/dotfiles
~/dotfiles/install.sh
```

Instala Bun (baseline, sin AVX y sin root; no hay Node), ccstatusline en versión fija, copia
`ccstatusline/` a `~/.config/ccstatusline/` y agrega `statusLine` a `~/.claude/settings.json`
sin tocar el resto. Requiere `jq`, `curl`, `unzip` y `python3`.

### Equipo local (donde corre Zed)

```bash
~/dotfiles/local/install-nerd-font.sh
```

Instala la Nerd Font. Luego, en el `settings.json` local de Zed:

```json
"terminal": { "font_family": "JetBrainsMono Nerd Font", "line_height": "standard" }
```

Las flechas requieren la Nerd Font. Para esquinas redondeadas, agrega `\ue0b6` en `startCaps` y `\ue0b4` en `endCaps` dentro de `powerline`.
