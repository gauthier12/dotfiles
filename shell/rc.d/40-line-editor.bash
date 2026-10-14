# shellcheck shell=bash
# Ligne de commande en mode vi. Ici et non dans ~/.inputrc, qui toucherait tous les programmes readline.

set -o vi
bind 'set keyseq-timeout 10' # délai après Échap (ms)

# Curseur : barre en insertion, bloc en normal (starship ne voit pas le mode en bash).
if [ "${TERM-}" != dumb ] && [ "${TERM-}" != linux ]; then
  bind 'set show-mode-in-prompt on'
  bind 'set vi-ins-mode-string \1\e[6 q\2'
  bind 'set vi-cmd-mode-string \1\e[2 q\2'
fi

# Touches spéciales ; ↑ ↓ et k j : historique filtré par le début de la ligne.
for _dotf_map in vi-insert vi-command; do
  bind -m "$_dotf_map" '"\e[A": history-search-backward'
  bind -m "$_dotf_map" '"\eOA": history-search-backward'
  bind -m "$_dotf_map" '"\e[B": history-search-forward'
  bind -m "$_dotf_map" '"\eOB": history-search-forward'
  bind -m "$_dotf_map" '"\e[1;5D": backward-word'
  bind -m "$_dotf_map" '"\e[1;5C": forward-word'
  bind -m "$_dotf_map" '"\e[H": beginning-of-line'
  bind -m "$_dotf_map" '"\eOH": beginning-of-line'
  bind -m "$_dotf_map" '"\e[F": end-of-line'
  bind -m "$_dotf_map" '"\eOF": end-of-line'
  bind -m "$_dotf_map" '"\e[3~": delete-char'
done
unset _dotf_map
bind -m vi-command '"k": history-search-backward'
bind -m vi-command '"j": history-search-forward'

# Insertion : raccourcis usuels.
bind -m vi-insert '"\C-a": beginning-of-line'
bind -m vi-insert '"\C-e": end-of-line'
bind -m vi-insert '"\C-l": clear-screen'
bind -m vi-insert '"\e[Z": menu-complete-backward'
