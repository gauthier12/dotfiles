# shellcheck shell=sh disable=SC2034
# Catppuccin pour XFCE : GTK (catppuccin/gtk, archivé), curseurs, xfce4-terminal.
# Pas les fenêtres : le xfwm4 de catppuccin/gtk 1.0.3 est livré sans ses images (fenêtres sans barre de titre).
# Accent mauve. Liens dans ~/.local/share, emplacements officiels ; « dotf theme » les applique.

_xfce_share="${XDG_DATA_HOME:-$HOME/.local/share}"
_xfce_flavours="latte frappe macchiato mocha"

pkg_latest() {
  _g=$(gh_latest catppuccin/gtk) && _c=$(gh_latest catppuccin/cursors) && _t=$(git_head https://github.com/catppuccin/xfce4-terminal) &&
    [ -n "$_g" ] && [ -n "$_c" ] && echo "$_g+$_c+$_t"
}

pkg_install() {
  _g=${1%%+*} _c=${1#*+} _c=${_c%%+*}
  mkdir themes icons
  for _f in $_xfce_flavours; do
    gh_get catppuccin/gtk "v$_g" "catppuccin-$_f-mauve-standard+default.zip" &&
      unzip -q -d themes "catppuccin-$_f-mauve-standard+default.zip" && rm "catppuccin-$_f-mauve-standard+default.zip" &&
      gh_get catppuccin/cursors "v$_c" "catppuccin-$_f-dark-cursors.zip" &&
      unzip -q -d icons "catppuccin-$_f-dark-cursors.zip" && rm "catppuccin-$_f-dark-cursors.zip" || return 1
  done
  rm -rf themes/*/xfwm4 themes/*-hdpi themes/*-xhdpi
  git clone -q --depth 1 https://github.com/catppuccin/xfce4-terminal xfce4-terminal || return 1
  mkdir -p "$_xfce_share/themes" "$_xfce_share/icons" "$_xfce_share/xfce4/terminal/colorschemes"
  for _d in themes/* icons/*; do ln -sfn "$DOTF_OPT/catppuccin-xfce/$_d" "$_xfce_share/$_d"; done
  for _d in xfce4-terminal/themes/*.theme; do ln -sf "$DOTF_OPT/catppuccin-xfce/$_d" "$_xfce_share/xfce4/terminal/colorschemes/"; done
}

# Les liens vers ce module ; XFCE revient à ses thèmes par défaut.
pkg_remove() {
  for _l in "$_xfce_share"/themes/* "$_xfce_share"/icons/* "$_xfce_share"/xfce4/terminal/colorschemes/*; do
    case $(readlink "$_l") in "$DOTF_OPT/catppuccin-xfce/"*) rm -f "$_l" ;; esac
  done
}
