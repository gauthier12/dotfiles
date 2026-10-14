# shellcheck shell=sh disable=SC2034
# Interface git en terminal. Méthode officielle : binaires précompilés.

pkg_bins=gitui

pkg_latest() { gh_latest gitui-org/gitui; }

pkg_install() {
  _f="gitui-linux-$(uname -m).tar.gz"
  gh_get gitui-org/gitui "v$1" "$_f" && tar -xzf "$_f" ./gitui && rm "$_f"
}
