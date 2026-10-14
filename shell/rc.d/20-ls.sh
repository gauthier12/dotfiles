# shellcheck shell=sh
# ls en couleur. LS_COLORS sert aussi à la complétion zsh.

if ls --color=auto -d . >/dev/null 2>&1; then
  alias ls='ls --color=auto'
fi
if [ -z "${LS_COLORS-}" ] && command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi
