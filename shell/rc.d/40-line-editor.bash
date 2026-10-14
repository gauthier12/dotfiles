# shellcheck shell=bash
# Édition de la ligne de commande (bash, via readline) : mode vi, comme en zsh.
# Réglé ici plutôt que dans ~/.inputrc, qui s'appliquerait à tous les programmes utilisant readline.
# starship ne peut pas afficher le mode en bash : c'est le curseur qui l'indique (barre en insertion,
# bloc en mode normal).

set -o vi
bind 'set keyseq-timeout 10' # attente après Échap, en ms

if [ "${TERM-}" != dumb ] && [ "${TERM-}" != linux ]; then
  bind 'set show-mode-in-prompt on'
  bind 'set vi-ins-mode-string \1\e[6 q\2'
  bind 'set vi-cmd-mode-string \1\e[2 q\2'
fi

# ↑ ↓ (et k j en mode normal) : historique filtré par le début de ce qui est déjà tapé.
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
# v en mode normal : édite la ligne dans $EDITOR (défaut de readline ; bash l'exécute à la sortie de l'éditeur).
