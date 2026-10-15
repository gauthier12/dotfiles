# Module zsh-syntax-highlighting. En dernier : il doit voir tous les widgets.
# Couleurs Catppuccin du thème (module catppuccin), à charger avant le plugin.
_dotf_f=$HOME/.local/opt/catppuccin/zsh-syntax-highlighting/themes/catppuccin_$DOTF_THEME-zsh-syntax-highlighting.zsh
[[ -r $_dotf_f ]] && source "$_dotf_f"
_dotf_f=$HOME/.local/opt/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -r $_dotf_f ]] && source "$_dotf_f"
unset _dotf_f
