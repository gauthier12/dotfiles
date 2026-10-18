# shellcheck shell=sh
# Couleur du nom d'hôte, tirée du nom : stable et propre à chaque machine.

# Couleur 256 : 1-6 ou 9-14 (ni noir, ni blanc, ni gris).
_dotf_n=$(($(uname -n | cksum | cut -d ' ' -f 1) % 12))
: "${DOTF_HOST_COLOR:=$((_dotf_n < 6 ? _dotf_n + 1 : _dotf_n + 3))}"
unset _dotf_n

# Config starship avec cette couleur, l'icône de l'hôte (ordinateur, ou serveur en ssh) et la couleur du trait
# (green ou red, argument), en cache. Un fichier par variante : le home peut être partagé.
_dotf_starship_config() {
  # Icônes Nerd Font : md-lan_connect en ssh, md-desktop_tower sinon.
  if [ -n "${SSH_CONNECTION-}" ]; then _dotf_icon=ssh _dotf_code='\\U000f0318'; else _dotf_icon=local _dotf_code='\\U000f01c5'; fi
  _dotf_src=$DOTF/config/starship.toml
  _dotf_dst=${XDG_CACHE_HOME:-$HOME/.cache}/dotf/starship-$DOTF_HOST_COLOR-$_dotf_icon-$1.toml
  # shellcheck disable=SC3013 # -nt : bash et zsh le connaissent
  if [ ! -f "$_dotf_dst" ] || [ "$_dotf_src" -nt "$_dotf_dst" ] || [ "$DOTF/shell/rc.d/85-host-color.sh" -nt "$_dotf_dst" ]; then
    mkdir -p "$(dirname "$_dotf_dst")"
    sed -e "s/HOST_COLOR/$DOTF_HOST_COLOR/" -e "s/HOST_ICON/$_dotf_code/" -e "s/LINE_COLOR/$1/" "$_dotf_src" >"$_dotf_dst"
  fi
  echo "$_dotf_dst"
}

# Trait du prompt vert ou rouge selon le code retour lu par starship (sauf STARSHIP_CONFIG choisi à la main).
_dotf_starship_line() {
  if [ "${STARSHIP_CMD_STATUS:-0}" = 0 ]; then STARSHIP_CONFIG=$_dotf_starship_ok; else STARSHIP_CONFIG=$_dotf_starship_err; fi
}
