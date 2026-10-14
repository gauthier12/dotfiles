# shellcheck shell=sh
# starship : prompt commun à bash et zsh (https://starship.rs).
# Binaire installé dans ~/.local/bin ; la config est dans $DOTF/config/starship.toml.

_starship_bin="$HOME/.local/bin/starship"

mod_installed() {
  [ -x "$_starship_bin" ]
}

mod_install() {
  mkdir -p "$(dirname "$_starship_bin")"
  _installer=$(fetch https://starship.rs/install.sh) || return 1
  printf '%s\n' "$_installer" | sh -s -- --yes --bin-dir "$(dirname "$_starship_bin")" >/dev/null
}

mod_update() {
  mod_install
}

mod_remove() {
  rm -f "$_starship_bin"
}
