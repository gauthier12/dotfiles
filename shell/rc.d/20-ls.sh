# shellcheck shell=sh
# ls en couleur quand le ls du système le permet (GNU ls).

if ls --color=auto -d . >/dev/null 2>&1; then
  alias ls='ls --color=auto'
fi
