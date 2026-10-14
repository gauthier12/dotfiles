# shellcheck shell=sh
# Titre du terminal : automatique (hôte, puis dossier ou commande en cours), ou fixé par setTitle.

_dotf_title() {
  case ${TERM-} in dumb | linux) return 0 ;; esac
  printf '\033]0;%s\007' "$1"
}

# setTitle <texte> fixe le titre ; setTitle sans argument revient au titre automatique.
setTitle() {
  # shellcheck disable=SC2034 # lu par 20-title.bash et 20-title.zsh
  DOTF_TITLE="$*"
  _dotf_title "$*"
}
