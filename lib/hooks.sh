# shellcheck shell=sh
# Lignes de branchement dans les fichiers rc de l'utilisateur.
# Chaque ligne se termine par le marqueur HOOK_MARK : pour débrancher à la main,
# il suffit de supprimer cette ligne.

HOOK_MARK='# dotf-hook'

# Fichiers branchés : "fichier:type", où type vaut env (shell/env.sh) ou init (shell/init.sh).
hook_targets() {
  _zdot=${ZDOTDIR:-$HOME}
  printf '%s\n' "$HOME/.profile:env" "$HOME/.bashrc:init"
  if [ -e "$HOME/.bash_profile" ]; then printf '%s\n' "$HOME/.bash_profile:env"; fi
  if command -v zsh >/dev/null 2>&1 || [ -e "$_zdot/.zshrc" ]; then
    printf '%s\n' "$_zdot/.zshenv:env" "$_zdot/.zshrc:init"
  fi
}

# Tous les fichiers où une ligne a pu être posée, pour la désinstallation.
hook_all_files() {
  _zdot=${ZDOTDIR:-$HOME}
  printf '%s\n' "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" "$_zdot/.zshenv" "$_zdot/.zshrc"
}

hook_line() {
  printf "if [ -r '%s/shell/%s.sh' ]; then DOTF='%s'; . '%s/shell/%s.sh'; fi  %s\n" \
    "$DOTF" "$1" "$DOTF" "$DOTF" "$1" "$HOOK_MARK"
}

hook_present() {
  [ -f "$1" ] && grep -qF -- "$HOOK_MARK" "$1"
}

# Supprime les lignes marquées en conservant le fichier (droits, cible d'un éventuel lien).
_hook_strip() {
  grep -vF -- "$HOOK_MARK" "$1" >"$1.dotf-tmp" || true
  cat "$1.dotf-tmp" >"$1"
  rm -f "$1.dotf-tmp"
}

hook_add() {
  _file=$1
  _line=$(hook_line "$2")
  if [ -f "$_file" ] && grep -qxF -- "$_line" "$_file"; then
    log_info "$(tilde "$_file") : déjà branché"
    return 0
  fi
  if [ ! -e "$_file" ]; then
    : >"$_file"
    state_add created "$_file"
  fi
  # Une ligne différente existe (dépôt déplacé) : on la remplace.
  if hook_present "$_file"; then _hook_strip "$_file"; fi
  if [ -s "$_file" ] && [ -n "$(tail -c 1 "$_file")" ]; then printf '\n' >>"$_file"; fi
  printf '%s\n' "$_line" >>"$_file"
  log_ok "$(tilde "$_file") : branché ($2)"
}

hook_remove() {
  _file=$1
  hook_present "$_file" || return 0
  _hook_strip "$_file"
  if state_has created "$_file" && [ ! -s "$_file" ]; then
    rm -f "$_file"
    log_ok "$(tilde "$_file") : supprimé (créé par dotf)"
  else
    log_ok "$(tilde "$_file") : débranché"
  fi
  state_del created "$_file"
}
