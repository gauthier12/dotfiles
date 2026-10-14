# shellcheck shell=bash
# Historique : grand, daté, sans doublons, partagé entre terminaux.

HISTSIZE=50000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth # sans doublons ni commandes précédées d'une espace
HISTTIMEFORMAT='%F %T  '
shopt -s histappend histverify

# À chaque prompt : écrit la dernière commande, lit celles des autres terminaux.
_dotf_history_sync() {
  history -a
  history -n
}
case ";${PROMPT_COMMAND-};" in
  *";_dotf_history_sync;"*) ;;
  *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_dotf_history_sync" ;;
esac
