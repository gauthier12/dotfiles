# shellcheck shell=sh
# Petites listes persistantes dans $DOTF_STATE (une entrée par ligne).
#   created : fichiers rc que dotf a créés (supprimés à la désinstallation s'ils sont vides)
#   links   : liens posés, au format "cible<TAB>source<TAB>sauvegarde"
#   modules : modules installés

state_file() { printf '%s/%s' "$DOTF_STATE" "$1"; }

state_has() {
  [ -f "$(state_file "$1")" ] && grep -qxF -- "$2" "$(state_file "$1")"
}

state_add() {
  state_has "$1" "$2" && return 0
  mkdir -p "$DOTF_STATE"
  printf '%s\n' "$2" >>"$(state_file "$1")"
}

state_list() {
  if [ -f "$(state_file "$1")" ]; then cat "$(state_file "$1")"; fi
}

# Retire les lignes dont le premier champ (séparé par une tabulation) vaut $2.
state_del() {
  _sf=$(state_file "$1")
  [ -f "$_sf" ] || return 0
  K="$2" awk -F '\t' '$1 != ENVIRON["K"]' "$_sf" >"$_sf.tmp" && mv "$_sf.tmp" "$_sf"
}
