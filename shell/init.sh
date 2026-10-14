# shellcheck shell=bash
# Shells interactifs (depuis ~/.bashrc et ~/.zshrc) : env.sh, puis rc.d du dépôt, puis rc.d local.
# *.sh : bash et zsh ; *.bash, *.zsh : ce shell seulement.

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

# Hors fonction : les variables des fragments restent globales.
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
