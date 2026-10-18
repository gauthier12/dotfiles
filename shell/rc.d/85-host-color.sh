# shellcheck shell=sh
# Couleur du nom d'hôte, tirée du nom : stable et propre à chaque machine.

# Une couleur d'accent Catppuccin (ni le bleu ni le mauve des blocs du prompt, ni le rouge des erreurs).
_dotf_n=$(($(uname -n | cksum | cut -d ' ' -f 1) % 9 + 1))
: "${DOTF_HOST_COLOR:=$(echo rosewater flamingo pink maroon peach yellow green teal sky | cut -d ' ' -f "$_dotf_n")}"
unset _dotf_n
# Pour le prompt de repli : la couleur du terminal la plus proche (ou le numéro donné dans DOTF_HOST_COLOR).
case $DOTF_HOST_COLOR in
  green) DOTF_HOST_ANSI=2 ;; peach | yellow) DOTF_HOST_ANSI=3 ;; teal | sky) DOTF_HOST_ANSI=6 ;;
  pink) DOTF_HOST_ANSI=5 ;; *[!0-9]*) DOTF_HOST_ANSI=1 ;; *) DOTF_HOST_ANSI=$DOTF_HOST_COLOR ;;
esac

# Config starship : couleur et icône de l'hôte (ordinateur, ou serveur en ssh), thème, trait vert ou rouge.
# Une variante par fichier, en cache, créée au premier besoin : le home peut être partagé.
if [ -n "${SSH_CONNECTION-}" ]; then _dotf_icon=ssh; else _dotf_icon=local; fi
_dotf_starship_dir=${XDG_CACHE_HOME:-$HOME/.cache}/dotf
# Recréées quand la config du dépôt change.
# shellcheck disable=SC3013 # -nt : bash et zsh le connaissent
if [ "$DOTF/config/starship.toml" -nt "$_dotf_starship_dir/starship.stamp" ] ||
  [ "$DOTF/shell/rc.d/85-host-color.sh" -nt "$_dotf_starship_dir/starship.stamp" ]; then
  mkdir -p "$_dotf_starship_dir" && rm -f "$_dotf_starship_dir"/starship-*.toml && : >"$_dotf_starship_dir/starship.stamp"
fi

_dotf_starship_config() { # _dotf_starship_config <green|red> : met STARSHIP_CONFIG sur la variante voulue
  STARSHIP_CONFIG=$_dotf_starship_dir/starship-$DOTF_HOST_COLOR-$_dotf_icon-${DOTF_THEME:-mocha}-$1.toml
  [ -f "$STARSHIP_CONFIG" ] && return 0
  # Icônes Nerd Font : md-lan_connect en ssh, md-desktop_tower sinon.
  if [ "$_dotf_icon" = ssh ]; then _dotf_code='\\U000f0318'; else _dotf_code='\\U000f01c5'; fi
  _dotf_pal=$HOME/.local/opt/catppuccin/starship/themes/${DOTF_THEME:-mocha}.toml
  _dotf_p=catppuccin_${DOTF_THEME:-mocha}
  if [ ! -r "$_dotf_pal" ]; then _dotf_p=ansi _dotf_pal=/dev/null; fi
  sed -e "s/HOST_COLOR/$DOTF_HOST_COLOR/g" -e "s/HOST_ICON/$_dotf_code/" -e "s/LINE_COLOR/$1/g" -e "s/PALETTE/$_dotf_p/" \
    "$DOTF/config/starship.toml" | cat - "$_dotf_pal" >"$STARSHIP_CONFIG"
}

# Avant chaque prompt, d'après le code retour lu par starship (sauf STARSHIP_CONFIG choisi à la main).
_dotf_starship_line() {
  if [ "${STARSHIP_CMD_STATUS:-0}" = 0 ]; then _dotf_starship_config green; else _dotf_starship_config red; fi
}
