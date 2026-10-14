# shellcheck shell=bash
# bash : le dossier seulement (la commande en cours demanderait un piège DEBUG, déjà pris par starship).

_dotf_title_prompt() { [ -n "${DOTF_TITLE-}" ] || _dotf_title "${HOSTNAME%%.*}: ${PWD/#$HOME/\~}"; }

case ";${PROMPT_COMMAND-};" in
  *";_dotf_title_prompt;"*) ;;
  *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_dotf_title_prompt" ;;
esac
