# shellcheck shell=sh disable=SC2034
# Joplin (application de bureau, AppImage). Les notes (~/.config/joplin-desktop) ne sont jamais touchées.
# Lanceur et icône comme le script officiel, en liens vers le dossier du module.

pkg_bins=joplin

_share="${XDG_DATA_HOME:-$HOME/.local/share}"

pkg_latest() { gh_latest laurent22/joplin; }

pkg_install() {
  [ "$(uname -m)" = x86_64 ] || return 1
  _f="Joplin-$1.AppImage"
  gh_get laurent22/joplin "v$1" "$_f" "$_f.sha512" &&
    mv "$_f" joplin && chmod +x joplin || return 1
  fetch https://joplinapp.org/images/Icon512.png >joplin.png || return 1
  cat >joplin.desktop <<DESKTOP
[Desktop Entry]
Name=Joplin
Comment=Joplin for Desktop
Exec=env APPIMAGELAUNCHER_DISABLE=TRUE "$DOTF_OPT/joplin/joplin" %u
Icon=joplin
StartupWMClass=appimagekit-joplin
Type=Application
Categories=Office;
MimeType=x-scheme-handler/joplin;
DESKTOP
  mkdir -p "$_share/applications" "$_share/icons/hicolor/512x512/apps"
  ln -sf "$DOTF_OPT/joplin/joplin.desktop" "$_share/applications/appimagekit-joplin.desktop"
  ln -sf "$DOTF_OPT/joplin/joplin.png" "$_share/icons/hicolor/512x512/apps/joplin.png"
}

pkg_remove() { rm -f "$_share/applications/appimagekit-joplin.desktop" "$_share/icons/hicolor/512x512/apps/joplin.png"; }
