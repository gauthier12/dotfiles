# shellcheck shell=sh
# Liens déclarés dans $DOTF/links : « source-dans-le-dépôt  cible » par ligne, ~/ accepté, # commente.
# Une cible existante est sauvegardée, puis restaurée à la désinstallation.
# État (links) : cible<TAB>source<TAB>sauvegarde.

links_wanted() { # cible<TAB>source
  [ -f "$DOTF/links" ] || return 0
  while read -r _src _dst _; do
    case $_src in '' | '#'*) continue ;; esac
    [ -n "$_dst" ] || { log_warn "links : cible manquante pour $_src"; continue; }
    # shellcheck disable=SC2088
    case $_dst in '~/'*) _dst="$HOME/${_dst#'~/'}" ;; esac
    printf '%s\t%s\n' "$_dst" "$DOTF/$_src"
  done <"$DOTF/links"
}

_link_state() { # ligne d'état de cette cible
  state_list links | K="$1" awk -F '\t' '$1 == ENVIRON["K"] { print; exit }'
}

_link_is() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }
_link_exists() { [ -e "$1" ] || [ -L "$1" ]; }

link_add() { # cible source
  if _link_is "$1" "$2"; then
    [ -n "$(_link_state "$1")" ] || state_add links "$1$TAB$2$TAB"
    log_info "$(tilde "$1") : déjà lié"
    return 0
  fi
  [ -e "$2" ] || { log_warn "$(tilde "$1") : source absente ($(tilde "$2")), ignoré"; return 0; }
  _backup=$(_link_state "$1" | cut -f3)
  if [ -L "$1" ] && [ -n "$(_link_state "$1")" ]; then
    rm -f "$1" # ancien lien de dotf
  elif _link_exists "$1"; then
    _backup="$DOTF_STATE/backup/$(date +%Y%m%d-%H%M%S)/${1#"$HOME"/}"
    mkdir -p "$(dirname "$_backup")"
    mv "$1" "$_backup"
    log_warn "$(tilde "$1") existait : sauvegardé dans $(tilde "$_backup")"
  fi
  mkdir -p "$(dirname "$1")"
  ln -s "$2" "$1"
  state_del links "$1"
  state_add links "$1$TAB$2$TAB$_backup"
  log_ok "$(tilde "$1") → $(tilde "$2")"
}

link_remove() { # cible source sauvegarde
  if _link_is "$1" "$2"; then
    rm -f "$1"
    log_ok "$(tilde "$1") : lien retiré"
  elif _link_exists "$1"; then
    log_warn "$(tilde "$1") : n'est plus le lien de dotf, laissé en place"
  fi
  if [ -n "$3" ] && _link_exists "$3"; then
    if _link_exists "$1"; then
      log_warn "sauvegarde non restaurée (cible occupée) : $(tilde "$3")"
    else
      mv "$3" "$1"
      log_ok "$(tilde "$1") : sauvegarde restaurée"
    fi
  fi
  state_del links "$1"
}

links_remove() { # [obsolete] : seulement les liens retirés de $DOTF/links
  _wanted=
  if [ "${1-}" = obsolete ]; then _wanted=$(links_wanted | cut -f1); fi
  state_list links | while IFS="$TAB" read -r _d _s _b; do
    if [ "${1-}" = obsolete ] && printf '%s\n' "$_wanted" | grep -qxF -- "$_d"; then continue; fi
    link_remove "$_d" "$_s" "$_b"
  done
}

links_install() {
  links_remove obsolete
  [ -n "$(links_wanted)" ] || { log_info "aucun lien déclaré"; return 0; }
  links_wanted | while IFS="$TAB" read -r _d _s; do link_add "$_d" "$_s"; done
}

links_status() {
  [ -n "$(links_wanted)" ] || { log_info "aucun lien déclaré"; return 0; }
  links_wanted | while IFS="$TAB" read -r _d _s; do
    if _link_is "$_d" "$_s"; then
      log_ok "$(tilde "$_d")"
    elif _link_exists "$_d"; then
      log_warn "$(tilde "$_d") : occupé par autre chose"
    else
      log_warn "$(tilde "$_d") : absent"
    fi
  done
}
