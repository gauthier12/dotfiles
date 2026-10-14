# shellcheck shell=bash
# Point d'entrée des shells interactifs bash et zsh, chargé depuis ~/.bashrc et ~/.zshrc.
#
# Charge, dans cet ordre :
#   1. shell/env.sh
#   2. les fragments de $DOTF/shell/rc.d, puis ceux de $DOTF_LOCAL/rc.d (la config locale passe après et peut surcharger)
# Dans chaque dossier, ordre alphabétique ; les *.sh sont chargés par les deux shells,
# les *.bash et *.zsh uniquement par le shell correspondant.

case $- in
  *i*) ;;
  *) return 0 ;;
esac

if [ -n "${ZSH_VERSION-}" ]; then
  DOTF_SHELL=zsh
elif [ -n "${BASH_VERSION-}" ]; then
  DOTF_SHELL=bash
else
  return 0
fi

: "${DOTF:=$HOME/.local/share/dotf}"
. "$DOTF/shell/env.sh"

# Boucle au niveau principal (et non dans une fonction) pour que les variables
# déclarées dans les fragments restent globales.
_dotf_glob_begin
for _dotf_dir in "$DOTF/shell/rc.d" "$DOTF_LOCAL/rc.d"; do
  for _dotf_f in "$_dotf_dir"/*; do
    case $_dotf_f in
      *.sh | *."$DOTF_SHELL")
        # shellcheck source=/dev/null
        if [ -r "$_dotf_f" ]; then . "$_dotf_f"; fi
        ;;
    esac
  done
done
_dotf_glob_end
unset _dotf_dir _dotf_f
