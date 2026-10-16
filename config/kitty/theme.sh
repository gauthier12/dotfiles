#!/bin/sh
# Couleurs Catppuccin de la variante choisie par « dotf theme » (module catppuccin), lues par kitty.conf.
t=$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/dotf/theme" 2>/dev/null)
cat "$HOME/.local/opt/catppuccin/kitty/themes/${t:-mocha}.conf" 2>/dev/null || true
