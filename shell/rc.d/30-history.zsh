# Historique zsh : grand, horodaté, sans doublons, partagé entre les terminaux ouverts.

HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=50000 # en mémoire ; plus grand que SAVEHIST pour que hist_expire_dups_first ait de la marge
SAVEHIST=10000 # sur disque

setopt extended_history       # date et durée de chaque commande
setopt share_history          # écrit chaque commande aussitôt et lit celles des autres terminaux
setopt hist_expire_dups_first # quand l'historique est plein, les doublons partent en premier
setopt hist_ignore_dups       # pas deux fois de suite la même commande
setopt hist_ignore_space      # une commande précédée d'une espace n'est pas enregistrée
setopt hist_verify            # !!, !$… : la ligne développée est montrée avant d'être lancée

# history : tout l'historique avec les dates ; avec des arguments, comme fc -l.
history() {
  if (( $# )); then builtin fc -il "$@"; else builtin fc -il 1; fi
}
