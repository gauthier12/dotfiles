# shellcheck shell=sh
# Liens symboliques déclarés dans $DOTF/links.
# Format : "<source relative au dépôt>  <cible>" par ligne, ~/ accepté, # pour commenter.
# Les chemins ne doivent pas contenir d'espaces.

# Affiche "cible<TAB>source" pour chaque lien voulu.
links_wanted() {
  [ -f "$DOTF/links" ] || return 0
  while read -r _src _dst _rest; do
    case $_src in '' | '#'*) continue ;; esac
    [ -n "$_dst" ] || { log_warn "links : cible manquante pour $_src"; continue; }
    # shellcheck disable=SC2088
    case $_dst in '~/'*) _dst="$HOME/${_dst#'~/'}" ;; esac
    printf '%s\t%s\n' "$_dst" "$DOTF/$_src"
  done <"$DOTF/links"
}

# Champ de sauvegarde enregistré pour une cible (vide si aucun).
_link_backup_of() {
  state_list links | K="$1" awk -F '\t' '$1 == ENVIRON["K"] { print $3; exit }'
}

# Vrai si dotf a enregistré un lien pour cette cible.
_link_known() {
  state_list links | K="$1" awk -F '\t' '$1 == ENVIRON["K"] { found = 1 } END { exit !found }'
}

link_add() {
  _dst=$1 _src=$2
  if [ -L "$_dst" ] && [ "$(readlink "$_dst")" = "$_src" ]; then
    _link_known "$_dst" || state_add links "$_dst$TAB$_src$TAB"
    log_info "$(tilde "$_dst") : déjà lié"
    return 0
  fi
  if [ ! -e "$_src" ]; then
    log_warn "$(tilde "$_dst") : source absente ($(tilde "$_src")), ignoré"
    return 0
  fi
  _backup=$(_link_backup_of "$_dst")
  if [ -L "$_dst" ] && _link_known "$_dst"; then
    rm -f "$_dst" # ancien lien posé par dotf (dépôt déplacé ou source modifiée)
  elif [ -e "$_dst" ] || [ -L "$_dst" ]; then
    case $_dst in
      "$HOME"/*) _rel=${_dst#"$HOME"/} ;;
      *) _rel=${_dst#/} ;;
    esac
    _backup="$DOTF_STATE/backup/$(date +%Y%m%d-%H%M%S)/$_rel"
    mkdir -p "$(dirname "$_backup")"
    mv "$_dst" "$_backup"
    log_warn "$(tilde "$_dst") existait : sauvegardé dans $(tilde "$_backup")"
  fi
  mkdir -p "$(dirname "$_dst")"
  ln -s "$_src" "$_dst"
  state_del links "$_dst"
  state_add links "$_dst$TAB$_src$TAB$_backup"
  log_ok "$(tilde "$_dst") → $(tilde "$_src")"
}

link_remove() {
  _dst=$1 _src=$2 _backup=$3
  if [ -L "$_dst" ] && [ "$(readlink "$_dst")" = "$_src" ]; then
    rm -f "$_dst"
    log_ok "$(tilde "$_dst") : lien retiré"
  elif [ -e "$_dst" ] || [ -L "$_dst" ]; then
    log_warn "$(tilde "$_dst") : n'est plus le lien de dotf, laissé en place"
  fi
  if [ -n "$_backup" ] && { [ -e "$_backup" ] || [ -L "$_backup" ]; }; then
    if [ -e "$_dst" ] || [ -L "$_dst" ]; then
      log_warn "sauvegarde non restaurée (cible occupée) : $(tilde "$_backup")"
    else
      mv "$_backup" "$_dst"
      log_ok "$(tilde "$_dst") : sauvegarde restaurée"
    fi
  fi
  state_del links "$_dst"
}

# Retire tous les liens enregistrés, ou seulement ceux absents de $DOTF/links si $1 = obsolete.
links_remove() {
  _wanted=
  if [ "${1-}" = obsolete ]; then _wanted=$(links_wanted | cut -f1); fi
  _current=$(state_list links)
  while IFS="$TAB" read -r _d _s _b; do
    [ -n "$_d" ] || continue
    if [ "${1-}" = obsolete ] && printf '%s\n' "$_wanted" | grep -qxF -- "$_d"; then continue; fi
    link_remove "$_d" "$_s" "$_b"
  done <<EOF
$_current
EOF
}

links_install() {
  links_remove obsolete
  _wanted=$(links_wanted)
  while IFS="$TAB" read -r _d _s; do
    [ -n "$_d" ] || continue
    link_add "$_d" "$_s"
  done <<EOF
$_wanted
EOF
}

links_status() {
  _wanted=$(links_wanted)
  [ -n "$_wanted" ] || { log_info "aucun lien déclaré"; return 0; }
  while IFS="$TAB" read -r _d _s; do
    if [ -L "$_d" ] && [ "$(readlink "$_d")" = "$_s" ]; then
      log_ok "$(tilde "$_d")"
    elif [ -e "$_d" ] || [ -L "$_d" ]; then
      log_warn "$(tilde "$_d") : occupé par autre chose"
    else
      log_warn "$(tilde "$_d") : absent"
    fi
  done <<EOF
$_wanted
EOF
}
