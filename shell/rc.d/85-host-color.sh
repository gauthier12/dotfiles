# shellcheck shell=sh
# Couleur du nom d'hôte, tirée du nom : stable et propre à chaque machine.

# Couleur 256 : 1-6 ou 9-14 (ni noir, ni blanc, ni gris).
_dotf_n=$(($(uname -n | cksum | cut -d ' ' -f 1) % 12))
: "${DOTF_HOST_COLOR:=$((_dotf_n < 6 ? _dotf_n + 1 : _dotf_n + 3))}"
unset _dotf_n

# Config starship avec cette couleur, en cache (un fichier par couleur : le home peut être partagé).
_dotf_starship_config() {
  _dotf_src=$DOTF/config/starship.toml
  _dotf_dst=${XDG_CACHE_HOME:-$HOME/.cache}/dotf/starship-$DOTF_HOST_COLOR.toml
  # shellcheck disable=SC3013 # -nt : bash et zsh le connaissent
  if [ ! -f "$_dotf_dst" ] || [ "$_dotf_src" -nt "$_dotf_dst" ]; then
    mkdir -p "$(dirname "$_dotf_dst")"
    sed "s/HOST_COLOR/$DOTF_HOST_COLOR/" "$_dotf_src" >"$_dotf_dst"
  fi
  echo "$_dotf_dst"
}
