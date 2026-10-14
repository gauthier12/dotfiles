# starship, sinon un prompt simple.

if [ "${TERM-}" != dumb ] && command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTF/config/starship.toml}"
  eval "$(starship init bash)"
else
  # [code retour] user@hôte dossier $
  _dotf_prompt() {
    local status=$?
    PS1=''
    if [ "$status" -ne 0 ]; then PS1='\[\e[31m\]'"$status"' \[\e[0m\]'; fi
    PS1+='\u@\h \[\e[34m\]\w\[\e[0m\] \$ '
  }
  case ";${PROMPT_COMMAND-};" in
    *";_dotf_prompt;"*) ;;
    *) PROMPT_COMMAND="_dotf_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
  esac
fi
