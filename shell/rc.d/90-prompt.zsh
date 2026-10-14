# starship, sinon un prompt simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG=${STARSHIP_CONFIG:-$(_dotf_starship_config)}
  eval "$(starship init zsh)"
else
  # user@hôte dossier % (% rouge si erreur)
  PROMPT="%n@%B%F{$DOTF_HOST_COLOR}%m%f%b %F{blue}%~%f %(?..%F{red})%#%f "
fi
