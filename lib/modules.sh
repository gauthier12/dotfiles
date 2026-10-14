# shellcheck shell=sh
# Modules : logiciels installés en espace utilisateur, choisis par machine dans DOTF_MODULES.
#
# Un module modules/<nom>.sh définit :
#   pkg_latest         affiche la dernière version
#   pkg_install <ver>  installe cette version dans le dossier courant
#   pkg_bins=          exécutables à lier dans ~/.local/bin (chemins relatifs au dossier)
#
# dotf fait le reste : dossier ~/.local/opt/<nom>, mise à jour, liens, désinstallation.

DOTF_OPT="$HOME/.local/opt"
DOTF_BIN="$HOME/.local/bin"

# --- Outils pour écrire un module ---------------------------------------------

fetch() { # fetch <url> : sur la sortie standard
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    log_warn "ni curl ni wget"
    return 1
  fi
}

gh_latest() { # gh_latest <dépôt GitHub> : dernière release, sans le « v »
  fetch "https://api.github.com/repos/$1/releases/latest" |
    sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1
}

gh_get() { # gh_get <dépôt> <tag> <fichier> [<fichier de sommes>] : télécharge et vérifie
  _url="https://github.com/$1/releases/download/$2"
  fetch "$_url/$3" >"$3" || return 1
  [ -n "${4-}" ] || return 0
  fetch "$_url/$4" >.sums || return 1
  check_sum "$3" .sums
}

check_sum() { # check_sum <fichier> <sommes> : « somme  nom » par ligne, ou une somme seule ; SHA-256 ou SHA-512
  _sum=$(awk -v f="$1" 'NF == 1 || $2 == f || $2 == "*" f { print $1; exit }' "$2")
  rm -f "$2"
  case ${#_sum} in
    64) _cmd=sha256sum ;;
    128) _cmd=sha512sum ;;
    *) return 1 ;;
  esac
  [ "$($_cmd "$1" | cut -d ' ' -f 1)" = "$_sum" ]
}

git_latest() { # git_latest <url> : dernier tag de version (x.y.z ou vx.y.z), tel quel
  git ls-remote --tags --refs "$1" | sed 's|.*refs/tags/||' |
    grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -V | tail -n 1
}

# --- Moteur --------------------------------------------------------------------

module_available() { [ -r "$DOTF/modules/$1.sh" ]; }
module_version() { cat "$DOTF_OPT/$1/.version" 2>/dev/null; }
module_installed() { [ -n "$(module_version "$1")" ]; }

# Vrai si ~/.local/bin/<lien> est libre ou déjà un lien vers ce module.
_module_bin_free() {
  [ ! -e "$DOTF_BIN/$2" ] && [ ! -L "$DOTF_BIN/$2" ] && return 0
  case $(readlink "$DOTF_BIN/$2") in "$DOTF_OPT/$1/"*) return 0 ;; esac
  return 1
}

_module_unlink() {
  for _l in "$DOTF_BIN"/*; do
    case $(readlink "$_l" 2>/dev/null) in "$DOTF_OPT/$1/"*) rm -f "$_l" ;; esac
  done
}

# Installe la dernière version si elle n'est pas déjà là.
module_install() (
  # shellcheck source=/dev/null
  . "$DOTF/modules/$1.sh"
  for _b in ${pkg_bins-}; do
    _module_bin_free "$1" "${_b##*/}" || { log_warn "$1 : $(tilde "$DOTF_BIN/${_b##*/}") existe déjà"; exit 1; }
  done
  _ver=$(pkg_latest)
  [ -n "$_ver" ] || { log_warn "$1 : dernière version introuvable"; exit 1; }
  [ "$_ver" != "$(module_version "$1")" ] || { log_info "$1 $_ver à jour"; exit 0; }
  mkdir -p "$DOTF_OPT" "$DOTF_BIN"
  _tmp=$(mktemp -d "$DOTF_OPT/.$1.XXXXXX")
  if ! (cd "$_tmp" && pkg_install "$_ver"); then
    rm -rf "$_tmp"
    log_warn "$1 $_ver : échec de l'installation"
    exit 1
  fi
  echo "$_ver" >"$_tmp/.version"
  _module_unlink "$1"
  rm -rf "${DOTF_OPT:?}/$1"
  mv "$_tmp" "$DOTF_OPT/$1"
  for _b in ${pkg_bins-}; do
    ln -s "$DOTF_OPT/$1/$_b" "$DOTF_BIN/${_b##*/}"
  done
  log_ok "$1 $_ver installé"
)

# Ne demande pas le fichier du module : on peut retirer un module supprimé du dépôt.
module_remove() {
  _module_unlink "$1"
  rm -rf "${DOTF_OPT:?}/$1"
  state_del modules "$1"
  log_ok "$1 désinstallé"
}

# Aligne l'installation sur DOTF_MODULES. Avec « update », met aussi à jour les modules présents.
module_sync() {
  for _m in $(state_list modules); do
    case " ${DOTF_MODULES-} " in *" $_m "*) ;; *) module_remove "$_m" ;; esac
  done
  for _m in ${DOTF_MODULES-}; do
    if ! module_available "$_m"; then
      log_warn "$_m : module inconnu"
    elif module_installed "$_m" && [ "${1-}" != update ]; then
      log_info "$_m $(module_version "$_m")"
    elif module_install "$_m"; then
      state_add modules "$_m"
    fi
  done
}

module_remove_all() {
  for _m in $(state_list modules); do module_remove "$_m"; done
}

module_status() {
  for _f in "$DOTF"/modules/*.sh; do
    _m=$(basename "$_f" .sh)
    case " ${DOTF_MODULES-} " in *" $_m "*) _off= ;; *) _off=" (inactif)" ;; esac
    if module_installed "$_m"; then
      log_ok "$_m $(module_version "$_m")$_off"
    elif [ -z "$_off" ]; then
      log_warn "$_m : actif mais non installé (« dotf install »)"
    else
      log_info "$_m (inactif)"
    fi
  done
}
