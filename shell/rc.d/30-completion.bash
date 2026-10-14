# Complétions des modules.
for _dotf_f in "$HOME"/.local/opt/*/completions/bash/*; do
  # shellcheck source=/dev/null
  [[ -r $_dotf_f ]] && source "$_dotf_f"
done
unset _dotf_f
