# Historique : grand, daté, sans doublons, partagé entre terminaux.

HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=50000 # mémoire (> SAVEHIST : marge pour hist_expire_dups_first)
SAVEHIST=10000 # disque

setopt extended_history share_history hist_expire_dups_first
setopt hist_ignore_dups hist_ignore_space # espace en tête : non enregistrée
setopt hist_reduce_blanks
setopt hist_verify                        # !! est montré avant d'être lancé

# Sans argument : tout l'historique, daté.
history() {
  if (( $# )); then builtin fc -il "$@"; else builtin fc -il 1; fi
}
