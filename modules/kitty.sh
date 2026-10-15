# shellcheck shell=sh disable=SC2034
# kitty, terminal (24 bits, ligatures). Installeur officiel : ~/.local/kitty.app, son emplacement par défaut.
# Liens, lanceurs et icône comme le décrit sa documentation ; config : config/kitty/kitty.conf.

pkg_bins="kitty kitten"

_kitty_app="$HOME/.local/kitty.app"
_kitty_apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

pkg_latest() { gh_latest kovidgoyal/kitty; }

pkg_install() {
  fetch https://sw.kovidgoyal.net/kitty/installer.sh >installer.sh || return 1
  sh installer.sh launch=n "installer=version-$1" >/dev/null 2>&1 || return 1
  rm installer.sh
  ln -s "$_kitty_app/bin/kitty" "$_kitty_app/bin/kitten" .
  # Lanceurs avec les chemins complets : le menu ne connaît pas toujours ~/.local/bin.
  for _d in kitty kitty-open; do
    sed -e "s|Icon=kitty|Icon=$_kitty_app/share/icons/hicolor/256x256/apps/kitty.png|" \
      -e "s|Exec=kitty|Exec=$_kitty_app/bin/kitty|" "$_kitty_app/share/applications/$_d.desktop" >"$_d.desktop"
  done
  mkdir -p "$_kitty_apps"
  ln -sf "$DOTF_OPT/kitty/kitty.desktop" "$DOTF_OPT/kitty/kitty-open.desktop" "$_kitty_apps/"
  ./kitty +complete setup bash | add_completion bash kitty
  ./kitty +complete setup zsh | add_completion zsh kitty
}

pkg_remove() { rm -rf "$_kitty_app" "$_kitty_apps/kitty.desktop" "$_kitty_apps/kitty-open.desktop"; }
