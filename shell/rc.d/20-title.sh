# shellcheck shell=sh
# setTitle <texte> : titre de la fenêtre du terminal.

setTitle() {
  printf '\033]0;%s\007' "$*"
}
