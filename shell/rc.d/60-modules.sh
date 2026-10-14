# shellcheck shell=sh
# Fonctions des modules (.rc.bash, .rc.zsh), ex. br de broot.
for _dotf_f in "$HOME"/.local/opt/*/.rc."$DOTF_SHELL"; do
  # shellcheck source=/dev/null
  if [ -r "$_dotf_f" ]; then . "$_dotf_f"; fi
done
unset _dotf_f
