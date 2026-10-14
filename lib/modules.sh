# shellcheck shell=sh
# Modules : logiciels installés en espace utilisateur, choisis par machine dans DOTF_MODULES.
#
# Un module modules/<nom>.sh définit :
#   pkg_latest         affiche la dernière version
#   pkg_install <ver>  installe cette version dans le dossier courant
#   pkg_bins=          exécutables à lier dans ~/.local/bin (chemins relatifs au dossier)
# Facultatif :
#   pkg_needs=         modules requis, installés avant lui
#   pkg_update         mise à jour sur place (dans son dossier), au lieu d'une réinstallation
#   .env.sh            fichier écrit dans son dossier, chargé par les shells et avant chaque installation
#
# dotf fait le reste : dossier ~/.local/opt/<nom>, mise à jour, liens, désinstallation.

DOTF_OPT="$HOME/.local/opt"
DOTF_BIN="$HOME/.local/bin"

# --- Outils pour les modules ---

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

download() { # download <url> [<url des sommes>] : dans le dossier courant, vérifié si sommes données
  _file=${1##*/}
  fetch "$1" >"$_file" || return 1
  [ -n "${2-}" ] || return 0
  fetch "$2" >.sums || return 1
  check_sum "$_file" .sums
}

gh_get() { # gh_get <dépôt> <tag> <fichier> [<fichier de sommes>]
  _url="https://github.com/$1/releases/download/$2"
  download "$_url/$3" ${4:+"$_url/$4"}
}

check_sum() { # check_sum <fichier> <sommes> : « somme  nom » par ligne, ou une somme seule ; SHA-256 ou SHA-512
  _sum=$(awk -v f="$1" '{ n = $2; sub(/^\*/, "", n); sub(/^\.\//, "", n) } NF == 1 || n == f { print $1; exit }' "$2")
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

crate_latest() { # crate_latest <crate> : dernière version stable publiée sur crates.io
  case ${#1} in
    1) _path=1/$1 ;;
    2) _path=2/$1 ;;
    3) _path=3/$(echo "$1" | cut -c1)/$1 ;;
    *) _path=$(echo "$1" | cut -c1-2)/$(echo "$1" | cut -c3-4)/$1 ;;
  esac
  fetch "https://index.crates.io/$_path" | grep '"yanked":false' |
    sed 's/.*"vers":"\([^"]*\)".*/\1/' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
}

# --- Moteur ---

# Les noms en _ (modèle) ne sont pas des modules.
module_available() { case $1 in _*) return 1 ;; esac; [ -r "$DOTF/modules/$1.sh" ]; }
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

# Modules installés : leurs variables (ex. cargo dans le PATH).
_module_envs() {
  for _e in "$DOTF_OPT"/*/.env.sh; do
    # shellcheck source=/dev/null
    if [ -r "$_e" ]; then . "$_e"; fi
  done
}

# Installe la dernière version, ou met à jour sur place avec pkg_update.
module_install() (
  _module_envs
  # shellcheck source=/dev/null
  . "$DOTF/modules/$1.sh"
  for _b in ${pkg_bins-}; do
    _module_bin_free "$1" "${_b##*/}" || { log_warn "$1 : $(tilde "$DOTF_BIN/${_b##*/}") existe déjà"; exit 1; }
  done
  _ver=$(pkg_latest)
  [ -n "$_ver" ] || { log_warn "$1 : dernière version introuvable"; exit 1; }
  if module_installed "$1" && command -v pkg_update >/dev/null; then
    (cd "$DOTF_OPT/$1" && pkg_update) || { log_warn "$1 : échec de la mise à jour"; exit 1; }
    echo "$_ver" >"$DOTF_OPT/$1/.version"
    log_info "$1 $_ver à jour"
    exit 0
  fi
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

_module_with_needs() { # le module, précédé de ses dépendances
  if module_available "$1"; then
    # shellcheck source=/dev/null
    for _n in $(. "$DOTF/modules/$1.sh" && echo "${pkg_needs-}"); do _module_with_needs "$_n"; done
  fi
  echo "$1"
}

# DOTF_MODULES et leurs dépendances, chacun une fois, dépendances d'abord.
module_wanted() {
  for _m in ${DOTF_MODULES-}; do _module_with_needs "$_m"; done | awk '!seen[$0]++'
}

# Aligne l'installation sur module_wanted. Avec « update », met aussi à jour les modules présents.
module_sync() {
  _wanted=" $(module_wanted | tr '\n' ' ') "
  for _m in $(state_list modules); do
    case $_wanted in *" $_m "*) ;; *) module_remove "$_m" ;; esac
  done
  for _m in $_wanted; do
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
  _wanted=" $(module_wanted | tr '\n' ' ') "
  for _f in "$DOTF"/modules/[!_]*.sh; do
    _m=$(basename "$_f" .sh)
    case $_wanted in *" $_m "*) _off= ;; *) _off=" (inactif)" ;; esac
    if module_installed "$_m"; then
      log_ok "$_m $(module_version "$_m")$_off"
    elif [ -z "$_off" ]; then
      log_warn "$_m : actif mais non installé (« dotf install »)"
    else
      log_info "$_m (inactif)"
    fi
  done
}
