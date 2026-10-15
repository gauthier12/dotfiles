# shellcheck shell=sh disable=SC2034
# Lapce, éditeur graphique : binaire officiel (version stable). Thèmes Catppuccin du module catppuccin.
# Lanceur et icône du dépôt officiel, en liens vers le dossier du module.

pkg_bins=lapce
pkg_needs=catppuccin

_share="${XDG_DATA_HOME:-$HOME/.local/share}"
_lapce_data="$_share/lapce-stable"
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
  _src="https://raw.githubusercontent.com/lapce/lapce/v$1/extra"
  fetch "$_src/images/logo.svg" >lapce.svg && fetch "$_src/linux/dev.lapce.lapce.desktop" >lapce.desktop || return 1
  sed -i "s|^Exec=lapce|Exec=$DOTF_OPT/lapce/lapce|" lapce.desktop
  mkdir -p "$_share/applications" "$_share/icons/hicolor/scalable/apps"
  ln -sf "$DOTF_OPT/lapce/lapce.desktop" "$_share/applications/dev.lapce.lapce.desktop"
  ln -sf "$DOTF_OPT/lapce/lapce.svg" "$_share/icons/hicolor/scalable/apps/dev.lapce.lapce.svg"
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
pkg_remove() {
  rm -f "$_lapce_data"/themes/catppuccin-*.toml "$_share/applications/dev.lapce.lapce.desktop" \
    "$_share/icons/hicolor/scalable/apps/dev.lapce.lapce.svg"
}
