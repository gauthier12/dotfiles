# shellcheck shell=sh disable=SC2034
# Navigation dans l'arborescence. Méthode officielle : binaires précompilés (archive multi-plateforme).

pkg_bins=broot

pkg_latest() { gh_latest Canop/broot; }

pkg_install() {
  gh_get Canop/broot "v$1" "broot_$1.zip" &&
    unzip -q -j "broot_$1.zip" "$(uname -m)-unknown-linux-musl/broot" && rm "broot_$1.zip"
}
