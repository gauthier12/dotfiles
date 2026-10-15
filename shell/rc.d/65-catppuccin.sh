# shellcheck shell=sh
# gitui et broot aux couleurs du thème (module catppuccin).
if [ -d "$HOME/.local/opt/catppuccin" ]; then
  gitui() { command gitui -t "$HOME/.local/opt/catppuccin/gitui/themes/catppuccin-$DOTF_THEME.ron" "$@"; }
  # broot n'a pas d'option d'ajout de config : sa config, puis la skin. La config est créée comme au premier lancement.
  broot() {
    _dotf_bc=${XDG_CONFIG_HOME:-$HOME/.config}/broot
    if [ ! -f "$_dotf_bc/conf.hjson" ]; then command broot --write-default-conf "$_dotf_bc" >/dev/null; fi
    command broot --conf "$_dotf_bc/conf.hjson;$HOME/.local/opt/catppuccin/broot/themes/$DOTF_THEME/catppuccin-$DOTF_THEME-mauve.hjson" "$@"
  }
fi
