# shellcheck shell=sh
# ls en couleur quand le ls du système le permet (GNU ls).
# LS_COLORS : couleurs par défaut de dircolors, sauf si déjà défini. zsh s'en sert aussi pour la complétion.

if ls --color=auto -d . >/dev/null 2>&1; then
  alias ls='ls --color=auto'
fi
if [ -z "${LS_COLORS-}" ] && command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi
