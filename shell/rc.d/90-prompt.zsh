# starship, sinon un prompt simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  # Trait vert ou rouge : _dotf_starship_line, après le precmd de starship qui lit le code retour.
  if [ -z "${STARSHIP_CONFIG-}" ]; then
    _dotf_starship_ok=$(_dotf_starship_config green) _dotf_starship_err=$(_dotf_starship_config red)
    export STARSHIP_CONFIG=$_dotf_starship_ok
    eval "$(starship init zsh)"
    precmd_functions+=(_dotf_starship_line)
  else
    eval "$(starship init zsh)"
  fi
else
  # user@hôte dossier % (% rouge si erreur)
  PROMPT="%n@%B%F{$DOTF_HOST_COLOR}%m%f%b %F{blue}%~%f %(?..%F{red})%#%f "
fi
