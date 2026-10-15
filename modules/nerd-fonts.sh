# shellcheck shell=sh disable=SC2034
# Polices Nerd Font, variante Mono (icônes sur une case) : celles de DOTF_FONTS (noms des archives Nerd Fonts).
# Visibles par les applications via un lien ~/.local/share/fonts/NerdFonts (dossier du script officiel).

DOTF_FONTS=${DOTF_FONTS:-Hasklig FiraCode}
_fonts_link="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts"

# La liste fait partie de la version : la changer réinstalle au prochain « dotf update ».
pkg_latest() {
  # shellcheck disable=SC2086 # la liste, espaces normalisés
  set -- $DOTF_FONTS
  _v=$(gh_latest ryanoasis/nerd-fonts) && [ -n "$_v" ] && echo "$_v ($*)"
}

pkg_install() {
  _v=${1%% *}
  for _f in $DOTF_FONTS; do
    gh_get ryanoasis/nerd-fonts "v$_v" "$_f.tar.xz" SHA-256.txt || return 1
    mkdir "$_f" && tar -xJf "$_f.tar.xz" -C "$_f" --wildcards '*NerdFontMono-*' 'LICENSE*' && rm "$_f.tar.xz" || return 1
  done
  mkdir -p "${_fonts_link%/*}"
  rm -f "${_fonts_link%/*}/nerd-fonts" # ancien nom
  ln -sfn "$DOTF_OPT/nerd-fonts" "$_fonts_link"
}

pkg_remove() { rm -f "$_fonts_link"; }
