# shellcheck shell=sh
# gitleaks : détection de secrets, utilisée en complément par le garde-fou (dotf scan).
# Binaire officiel téléchargé depuis les releases GitHub, vérifié par somme SHA-256, installé dans ~/.local/bin.

_gitleaks_bin="$HOME/.local/bin/gitleaks"
_gitleaks_repo=gitleaks/gitleaks

mod_installed() {
  [ -x "$_gitleaks_bin" ]
}

_gitleaks_arch() {
  case $(uname -m) in
    x86_64 | amd64) echo x64 ;;
    aarch64 | arm64) echo arm64 ;;
    armv7*) echo armv7 ;;
    armv6*) echo armv6 ;;
    i?86) echo x32 ;;
    *) return 1 ;;
  esac
}

# Dernière version publiée, sans le « v » (ex. 8.24.3).
_gitleaks_latest() {
  fetch "https://api.github.com/repos/$_gitleaks_repo/releases/latest" |
    sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1
}

_gitleaks_current() {
  "$_gitleaks_bin" version 2>/dev/null | sed 's/^v//'
}

mod_install() {
  [ "$(uname -s)" = Linux ] || { log_warn "gitleaks : seul Linux est géré"; return 1; }
  _arch=$(_gitleaks_arch) || { log_warn "gitleaks : architecture $(uname -m) non gérée"; return 1; }
  _ver=$(_gitleaks_latest)
  [ -n "$_ver" ] || { log_warn "gitleaks : impossible de connaître la dernière version"; return 1; }
  _url="https://github.com/$_gitleaks_repo/releases/download/v$_ver"
  _tar="gitleaks_${_ver}_linux_${_arch}.tar.gz"
  _tmp=$(mktemp -d)
  if fetch "$_url/$_tar" >"$_tmp/$_tar" &&
    fetch "$_url/gitleaks_${_ver}_checksums.txt" >"$_tmp/sums" &&
    grep " $_tar\$" "$_tmp/sums" | (cd "$_tmp" && sha256sum -c --status) &&
    tar -xzf "$_tmp/$_tar" -C "$_tmp" gitleaks; then
    mkdir -p "$(dirname "$_gitleaks_bin")"
    mv "$_tmp/gitleaks" "$_gitleaks_bin"
    chmod +x "$_gitleaks_bin"
    rm -rf "$_tmp"
  else
    rm -rf "$_tmp"
    log_warn "gitleaks : échec du téléchargement ou de la vérification de $_tar"
    return 1
  fi
}

mod_update() {
  _latest=$(_gitleaks_latest)
  [ -n "$_latest" ] || return 1
  [ "$(_gitleaks_current)" = "$_latest" ] && return 0
  mod_install
}

mod_remove() {
  rm -f "$_gitleaks_bin"
}
