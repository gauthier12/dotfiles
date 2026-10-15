# shellcheck shell=sh disable=SC2034
# Lapce, éditeur graphique : binaire officiel (version stable). Thèmes Catppuccin du module catppuccin.

pkg_bins=lapce
pkg_needs=catppuccin

_lapce_data="${XDG_DATA_HOME:-$HOME/.local/share}/lapce-stable"
_lapce_settings="${XDG_CONFIG_HOME:-$HOME/.config}/lapce-stable/settings.toml"

pkg_latest() { gh_latest lapce/lapce; }

pkg_install() {
  case $(uname -m) in
    x86_64) _arch=amd64 ;;
    aarch64) _arch=arm64 ;;
    *) return 1 ;;
  esac
  gh_get lapce/lapce "v$1" "lapce-linux-$_arch.tar.gz" &&
    tar -xzf "lapce-linux-$_arch.tar.gz" --strip-components=1 Lapce/lapce && rm "lapce-linux-$_arch.tar.gz" || return 1
  # Thèmes : liens dans le dossier de thèmes de Lapce.
  mkdir -p "$_lapce_data/themes"
  for _t in "$DOTF_OPT"/catppuccin/lapce/catppuccin-*.toml; do
    ln -sf "$_t" "$_lapce_data/themes/"
  done
  # Thème par défaut, seulement au premier lancement : ensuite, les réglages sont ceux de Lapce.
  if [ ! -e "$_lapce_settings" ]; then
    mkdir -p "$(dirname "$_lapce_settings")"
    printf '[core]\ncolor-theme = "Catppuccin Mocha"\n' >"$_lapce_settings"
  fi
}

# Les réglages de Lapce restent.
pkg_remove() { rm -f "$_lapce_data"/themes/catppuccin-*.toml; }
