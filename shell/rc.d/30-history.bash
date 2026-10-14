# shellcheck shell=bash
# Historique bash : grand, horodaté, sans doublons, partagé entre les terminaux ouverts.

HISTSIZE=50000            # en mémoire
HISTFILESIZE=10000        # sur disque
HISTCONTROL=ignoreboth    # ni doublons consécutifs, ni commandes précédées d'une espace
HISTTIMEFORMAT='%F %T  '  # date affichée par history
shopt -s histappend       # ajoute au fichier au lieu de l'écraser
shopt -s histverify       # !!, !$… : la ligne développée est montrée avant d'être lancée

# À chaque prompt : écrit la dernière commande et lit celles des autres terminaux.
_dotf_history_sync() {
  history -a
  history -n
}
case ";${PROMPT_COMMAND-};" in
  *";_dotf_history_sync;"*) ;;
  *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_dotf_history_sync" ;;
esac
