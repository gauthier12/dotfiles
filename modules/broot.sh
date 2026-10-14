# shellcheck shell=sh disable=SC2034
# Navigation dans l'arborescence. Méthode officielle : binaires précompilés (archive multi-plateforme).
# La fonction br (cd en quittant broot) est chargée par les shells, sans toucher aux fichiers rc.

pkg_bins=broot

pkg_latest() { gh_latest Canop/broot; }

pkg_install() {
  _z="broot_$1.zip"
  gh_get Canop/broot "v$1" "$_z" &&
    unzip -q -j "$_z" "$(uname -m)-unknown-linux-musl/broot" || return 1
  for _c in broot br; do
    unzip -p "$_z" "completion/$_c.bash" | add_completion bash "$_c"
    unzip -p "$_z" "completion/_$_c" | add_completion zsh "$_c"
  done
  rm "$_z"
  ./broot --print-shell-function bash >.rc.bash
  ./broot --print-shell-function zsh >.rc.zsh
  # Sinon broot propose, au premier lancement, d'écrire br dans les fichiers rc.
  ./broot --set-install-state installed
}

pkg_remove() { rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/broot/launcher"; }
