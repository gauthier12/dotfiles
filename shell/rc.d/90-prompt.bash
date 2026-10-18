# starship, sinon un prompt simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  # Variante de la config (thème, trait vert ou rouge) : _dotf_starship_line, lancé par starship après lecture du code retour (STARSHIP_PROMPT_COMMAND).
  if [ -z "${STARSHIP_CONFIG-}" ]; then
    _dotf_starship_config green
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_dotf_starship_line"
  fi
  export STARSHIP_CONFIG
  eval "$(starship init bash)"
else
  # user@hôte dossier $ ($ rouge si erreur)
  _dotf_prompt() {
    local status=$? color=0
    [ "$status" -eq 0 ] || color=31
    PS1='\u@\[\e[1;38;5;'"$DOTF_HOST_ANSI"'m\]\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\] \[\e['"$color"'m\]\$\[\e[0m\] '
  }
  case ";${PROMPT_COMMAND-};" in
    *";_dotf_prompt;"*) ;;
    *) PROMPT_COMMAND="_dotf_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
  esac
fi
