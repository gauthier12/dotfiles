# shellcheck shell=sh disable=SC2034
# Joplin (application de bureau, AppImage). Les notes (~/.config/joplin-desktop) ne sont jamais touchées.

pkg_bins=joplin

pkg_latest() { gh_latest laurent22/joplin; }

pkg_install() {
  [ "$(uname -m)" = x86_64 ] || return 1
  _f="Joplin-$1.AppImage"
  gh_get laurent22/joplin "v$1" "$_f" "$_f.sha512" &&
    mv "$_f" joplin && chmod +x joplin
}
