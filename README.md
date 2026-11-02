# dotfiles

Configuración personal de herramientas de terminal.

- `claude-statusline/`: tema de la barra de estado de Claude Code ([claude-statusline](https://github.com/felipeelias/claude-statusline)).

## Uso

```bash
git clone <url-de-este-repo> ~/dotfiles
~/dotfiles/install.sh
```

El script descarga el binario (verifica el checksum), copia la configuración a
`~/.config/claude-statusline/` y agrega `statusLine` a `~/.claude/settings.json`
sin tocar el resto de ese archivo. No se guardan permisos, tokens ni rutas privadas.
