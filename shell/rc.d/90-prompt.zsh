# starship, sinon un prompt simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  # Variante de la config (thème, trait vert ou rouge) : _dotf_starship_line, après le precmd de starship qui lit le code retour.
  if [ -z "${STARSHIP_CONFIG-}" ]; then
    _dotf_starship_config green
    export STARSHIP_CONFIG
    eval "$(starship init zsh)"
    precmd_functions+=(_dotf_starship_line)
  else
    eval "$(starship init zsh)"
  fi
else
  # user@hôte dossier % (% rouge si erreur)
  PROMPT="%n@%B%F{$DOTF_HOST_ANSI}%m%f%b %F{blue}%~%f %(?..%F{red})%#%f "
fi
