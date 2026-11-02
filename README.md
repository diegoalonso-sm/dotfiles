# dotfiles

Configuración personal de la barra de estado de Claude Code. Funciona en un terminal, en Zed y en VS Code.

La barra tiene tres líneas con la paleta Tokyo Night:

```
 Opus 5  high  ~/proyecto  main  76k/200k 38%  1hr 31m
╭╴5h ●●●●●●●●●○○○○○○○○○○○○○○○○ 38% ↻ 15:45 (2h13m)
╰╴7d ●●●●●●●○○○○○○○○○○○○○○○○○ 29% ↻ Thu 05 (3d4h)
```

- Línea 1: modelo, esfuerzo de razonamiento, directorio, rama, contexto en tokens y duración de la sesión.
- Líneas 2 y 3: uso del límite de 5 horas y del semanal. Los puntos llenos cambian de color con el uso (verde bajo 70 %, amarillo hasta 89 %, rojo desde 90 %) y al lado queda el tiempo que falta para el reinicio.

Si tu plan no informa límites de uso, esas dos líneas quedan vacías.

## Cómo está armado

Hay dos máquinas distintas, y cada una necesita su parte:

| Dónde | Qué se instala | Con qué |
|---|---|---|
| **Donde corre Claude Code** (tu equipo, un servidor o un contenedor) | La barra y su configuración | `install.sh` |
| **Donde se dibuja el terminal** (tu equipo local) | La fuente, porque las flechas y las esquinas redondeadas son símbolos de la Nerd Font | `local/install-nerd-font.sh` o `.ps1`, más un ajuste en tu editor |

Si trabajas en una sola máquina, son la misma y haces los dos pasos ahí. Si te conectas por SSH, por ejemplo con Zed Remote o VS Code Remote, Claude Code corre en el servidor y la fuente va en tu equipo.

## 1. Instalar la barra

Donde corre Claude Code:

```bash
git clone https://github.com/<tu-usuario>/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Requiere `curl`, `unzip`, `jq` y `python3`. El script:

1. Descarga Bun (versión baseline, sin AVX) y verifica su checksum. No usa Node ni necesita permisos de administrador.
2. Instala `ccstatusline` en una versión fija.
3. Copia `ccstatusline/` a `~/.config/ccstatusline/`.
4. Agrega la clave `statusLine` a `~/.claude/settings.json` sin tocar el resto del archivo.

Se puede ejecutar varias veces sin romper nada. Después reinicia Claude Code.

Plataformas: Linux x86_64 y arm64, macOS Intel y Apple Silicon. En Windows, usa WSL.

## 2. Instalar la fuente

En el equipo donde se dibuja el terminal. Instala JetBrainsMono Nerd Font.

| Sistema | Comando |
|---|---|
| macOS o Linux | `~/dotfiles/local/install-nerd-font.sh` |
| Windows (PowerShell) | `powershell -ExecutionPolicy Bypass -File .\local\install-nerd-font.ps1` |

El script de Windows instala la fuente solo para tu usuario, sin pedir administrador. Cierra y abre de nuevo el editor o el terminal después.

## 3. Configurar la fuente

Elige tu caso. En los tres hay que usar la fuente en el terminal, no en el editor de código.

### Un terminal cualquiera

Cambia la fuente en las preferencias de tu terminal a `JetBrainsMono Nerd Font` (o `JetBrainsMono Nerd Font Mono`) y reinicia el terminal.

### Zed

Abre la configuración con `zed: open settings` y agrega:

```json
"terminal": {
  "font_family": "JetBrainsMono Nerd Font",
  "line_height": "standard"
}
```

- Si conectas por SSH, va en el `settings.json` **local**, no en el del servidor.
- `line_height: "standard"` evita huecos entre filas que cortan las curvas. Si quieres más aire entre líneas, usa `{ "custom": 1.2 }`.
- Rutas del archivo: macOS y Linux `~/.config/zed/settings.json`, Windows `%APPDATA%\Zed\settings.json`.

### VS Code

Abre la configuración de usuario (`Ctrl+Shift+P` → "Preferences: Open User Settings (JSON)") y agrega:

```json
"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
"terminal.integrated.minimumContrastRatio": 1
```

- El ajuste de contraste evita que VS Code cambie los colores de los segmentos.
- Con Remote SSH o WSL, va en la configuración de **usuario** del equipo local, no en la del servidor.

## 4. Comprobar que funciona

En el mismo terminal donde ves la barra:

```bash
echo $'   '
```

Debes ver una media luna a la izquierda, una flecha sólida, una media luna a la derecha y una flecha fina. Si ves cuadros o signos de interrogación, la fuente no se está aplicando.

Para ver la barra con datos de ejemplo, sin abrir Claude Code:

```bash
echo '{"model":{"display_name":"Opus 5"},"cwd":"'"$PWD"'","context_window":{"context_window_size":200000,"current_usage":{"input_tokens":3000,"cache_read_input_tokens":73000}},"rate_limits":{"five_hour":{"used_percentage":38,"resets_at":'$(date -d '+2 hours' +%s)'},"seven_day":{"used_percentage":29,"resets_at":'$(date -d '+3 days' +%s)'}}}' | ~/.local/bin/ccstatusline
```

En macOS cambia `date -d '+2 hours'` por `date -v+2H`.

## Problemas comunes

| Síntoma | Causa probable |
|---|---|
| Cuadros o signos de interrogación en lugar de flechas | La fuente no está instalada o el editor usa otro nombre. Prueba `JetBrainsMono NF` o `JetBrainsMono Nerd Font Mono`. |
| La fuente está instalada pero no cambia nada | Hay que cerrar el editor por completo y abrirlo de nuevo. |
| Huecos entre los segmentos o curvas cortadas | La altura de línea del terminal. En Zed usa `"line_height": "standard"`. |
| La fuente no se aplica con SSH | El ajuste está en la configuración del servidor. Debe ir en la del equipo local. |
| Colores distintos a los esperados en VS Code | Falta `terminal.integrated.minimumContrastRatio: 1`. |
| Las líneas de uso salen vacías | Tu plan no informa límites a Claude Code (requiere la versión 2.1.80 o posterior). |
| La barra se corta en un panel angosto | Baja `ancho=100` en `ccstatusline/usage-bars.sh`. Con 60 cabe en la mayoría de los paneles. |

## Personalizar

Todo está en `ccstatusline/`:

| Archivo | Qué controla |
|---|---|
| `settings.json` | Qué datos van en la línea principal, sus colores y el estilo powerline. |
| `usage-bars.sh` | Las barras de 5 horas y semanal: ancho, símbolos, umbrales de color y formato de la hora. |
| `context-tokens.sh` | El contexto como tokens usados sobre el total. |

Los widgets disponibles están en la [documentación de ccstatusline](https://github.com/sirmalloc/ccstatusline/blob/main/docs/USAGE.md). También puedes abrir su editor interactivo con `~/.local/bin/ccstatusline` y copiar el resultado de `~/.config/ccstatusline/settings.json` al repo.

Para aplicar un cambio, edita el archivo en el repo y ejecuta `./install.sh`. Para probarlo antes, usa el comando de la sección 4.

## Estructura

```
install.sh                    Instalador idempotente (barra y configuración)
ccstatusline/
  settings.json               Configuración de ccstatusline
  usage-bars.sh               Barras de 5 horas y 7 días
  context-tokens.sh           Contexto en tokens
local/
  install-nerd-font.sh        Fuente en macOS y Linux
  install-nerd-font.ps1       Fuente en Windows
```

## Qué no se guarda aquí

Permisos, tokens, hooks con rutas privadas ni el `settings.json` completo de Claude Code. El instalador solo agrega la clave `statusLine`.
