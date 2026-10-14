# shellcheck shell=sh
# Une ligne marquée « # dotf-hook » par fichier rc. La supprimer suffit à débrancher.

HOOK_MARK='# dotf-hook'

# « fichier:type », type env (shell/env.sh) ou init (shell/init.sh).
hook_targets() {
  _z=${ZDOTDIR:-$HOME}
  echo "$HOME/.profile:env"
  echo "$HOME/.bashrc:init"
  if [ -e "$HOME/.bash_profile" ]; then echo "$HOME/.bash_profile:env"; fi
  if command -v zsh >/dev/null 2>&1 || [ -e "$_z/.zshrc" ]; then
    echo "$_z/.zshenv:env"
    echo "$_z/.zshrc:init"
  fi
}

hook_line() {
  printf "if [ -r '%s/shell/%s.sh' ]; then DOTF='%s'; . '%s/shell/%s.sh'; fi  %s\n" \
    "$DOTF" "$1" "$DOTF" "$DOTF" "$1" "$HOOK_MARK"
}

hook_present() { [ -f "$1" ] && grep -qF -- "$HOOK_MARK" "$1"; }

# Réécrit le fichier en place : garde ses droits, et la cible s'il s'agit d'un lien.
hook_strip() {
  grep -vF -- "$HOOK_MARK" "$1" >"$1.dotf-tmp" || true
  cat "$1.dotf-tmp" >"$1"
  rm -f "$1.dotf-tmp"
}

hook_add() {
  _line=$(hook_line "$2")
  if [ -f "$1" ] && grep -qxF -- "$_line" "$1"; then
    log_info "$(tilde "$1") : déjà branché"
    return 0
  fi
  if [ ! -e "$1" ]; then
    : >"$1"
    state_add created "$1"
  fi
  # Ancienne ligne (dépôt déplacé) : remplacée.
  if hook_present "$1"; then hook_strip "$1"; fi
  if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then echo >>"$1"; fi
  echo "$_line" >>"$1"
  log_ok "$(tilde "$1") : branché ($2)"
}

hook_remove() {
  hook_present "$1" || return 0
  hook_strip "$1"
  if state_has created "$1" && [ ! -s "$1" ]; then
    rm -f "$1"
    log_ok "$(tilde "$1") : supprimé (créé par dotf)"
  else
    log_ok "$(tilde "$1") : débranché"
  fi
  state_del created "$1"
}

hooks_install() {
  for _t in $(hook_targets); do hook_add "${_t%:*}" "${_t##*:}"; done
}

# Tous les fichiers possibles, même ceux qui ne sont plus des cibles.
hooks_remove() {
  _z=${ZDOTDIR:-$HOME}
  for _f in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" "$_z/.zshenv" "$_z/.zshrc"; do
    hook_remove "$_f"
  done
}

hooks_status() {
  for _t in $(hook_targets); do
    _f=${_t%:*}
    if [ -f "$_f" ] && grep -qxF -- "$(hook_line "${_t##*:}")" "$_f"; then
      log_ok "$(tilde "$_f")"
    elif hook_present "$_f"; then
      log_warn "$(tilde "$_f") : ligne obsolète, relancer « dotf install »"
    else
      log_warn "$(tilde "$_f") : non branché"
    fi
  done
}
