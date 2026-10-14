# shellcheck shell=sh
# setTitle <texte> : change le titre de la fenêtre du terminal.

setTitle() {
  printf '\033]0;%s\007' "$*"
}
