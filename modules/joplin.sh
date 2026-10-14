# shellcheck shell=sh
# joplin : application de notes Joplin (version bureau, AppImage officielle).
# L'AppImage est téléchargée depuis les releases GitHub et vérifiée par somme SHA-512.
# Elle est rangée dans ~/.local/opt/joplin, et la commande « joplin » (~/.local/bin/joplin) la lance.
# Les notes et réglages (~/.config/joplin-desktop) ne sont jamais touchés, même à la désinstallation.

_joplin_dir="$HOME/.local/opt/joplin"
_joplin_bin="$HOME/.local/bin/joplin"
_joplin_repo=laurent22/joplin

mod_installed() {
  [ -x "$_joplin_dir/Joplin.AppImage" ] && [ -L "$_joplin_bin" ]
}

# Dernière version publiée, sans le « v » (ex. 3.7.21).
_joplin_latest() {
  fetch "https://api.github.com/repos/$_joplin_repo/releases/latest" |
    sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1
}

# Vrai si ~/.local/bin/joplin est libre ou déjà le lien posé par ce module.
_joplin_bin_ours() {
  if [ -e "$_joplin_bin" ] || [ -L "$_joplin_bin" ]; then
    [ "$(readlink "$_joplin_bin")" = "$_joplin_dir/Joplin.AppImage" ]
  fi
}

mod_install() {
  _joplin_bin_ours || { log_warn "joplin : $_joplin_bin existe déjà (autre programme ?), rien n'est installé"; return 1; }
  case $(uname -s)/$(uname -m) in
    Linux/x86_64) ;;
    *) log_warn "joplin : seul Linux x86_64 est géré"; return 1 ;;
  esac
  _ver=$(_joplin_latest)
  [ -n "$_ver" ] || { log_warn "joplin : impossible de connaître la dernière version"; return 1; }
  _app="Joplin-$_ver.AppImage"
  _url="https://github.com/$_joplin_repo/releases/download/v$_ver/$_app"
  mkdir -p "$_joplin_dir"
  _tmp=$(mktemp -d "$_joplin_dir/.dl.XXXXXX")
  if fetch "$_url" >"$_tmp/$_app" &&
    _sum=$(fetch "$_url.sha512") &&
    printf '%s  %s\n' "$_sum" "$_app" | (cd "$_tmp" && sha512sum -c --status); then
    chmod +x "$_tmp/$_app"
    mv "$_tmp/$_app" "$_joplin_dir/Joplin.AppImage"
    printf '%s\n' "$_ver" >"$_joplin_dir/VERSION"
    rm -rf "$_tmp"
  else
    rm -rf "$_tmp"
    log_warn "joplin : échec du téléchargement ou de la vérification de $_app"
    return 1
  fi
  mkdir -p "$(dirname "$_joplin_bin")"
  ln -sfn "$_joplin_dir/Joplin.AppImage" "$_joplin_bin"
}

mod_update() {
  _latest=$(_joplin_latest)
  [ -n "$_latest" ] || return 1
  [ "$(cat "$_joplin_dir/VERSION" 2>/dev/null)" = "$_latest" ] && return 0
  mod_install
}

mod_remove() {
  if [ -L "$_joplin_bin" ] && _joplin_bin_ours; then rm -f "$_joplin_bin"; fi
  rm -rf "$_joplin_dir"
}
