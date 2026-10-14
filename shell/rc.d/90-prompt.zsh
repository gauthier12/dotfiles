# Prompt : starship s'il est installé (et que le terminal le permet), sinon un PROMPT simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTF/config/starship.toml}"
  eval "$(starship init zsh)"
else
  # [code retour en rouge s'il est non nul] user@hôte dossier %
  PROMPT='%(?..%F{red}%? %f)%n@%m %F{blue}%~%f %# '
fi
