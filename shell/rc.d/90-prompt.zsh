# starship, sinon un prompt simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTF/config/starship.toml}"
  eval "$(starship init zsh)"
else
  # [code retour] user@hôte dossier %
  PROMPT='%(?..%F{red}%? %f)%n@%m %F{blue}%~%f %# '
fi
