# shellcheck shell=sh
# Une ligne marquée « dotf-hook » par fichier rc (un petit bloc pour ~/.Xresources). La supprimer suffit à débrancher.

HOOK_MARK='dotf-hook'

# « fichier:type », type env (shell/env.sh), init (shell/init.sh), vim (config/vim/vimrc), xres (config/x/Xresources)
# ou tmux (config/tmux/tmux.conf).
hook_targets() {
  _z=${ZDOTDIR:-$HOME}
  echo "$HOME/.profile:env"
  echo "$HOME/.bashrc:init"
  if [ -e "$HOME/.bash_profile" ]; then echo "$HOME/.bash_profile:env"; fi
  if command -v zsh >/dev/null 2>&1 || [ -e "$_z/.zshrc" ]; then
    echo "$_z/.zshenv:env"
    echo "$_z/.zshrc:init"
  fi
  if command -v vim >/dev/null 2>&1 || command -v gvim >/dev/null 2>&1; then echo "$(hook_vimrc):vim"; fi
  if command -v xrdb >/dev/null 2>&1 || [ -e "$HOME/.Xresources" ]; then echo "$HOME/.Xresources:xres"; fi
  if command -v tmux >/dev/null 2>&1; then echo "$(hook_tmuxconf):tmux"; fi
}

# tmux lit ~/.tmux.conf, sinon ~/.config/tmux/tmux.conf.
hook_tmuxconf() {
  _x=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
  if [ ! -e "$HOME/.tmux.conf" ] && [ -e "$_x" ]; then echo "$_x"; else echo "$HOME/.tmux.conf"; fi
}

# vim lit ~/.vimrc, sinon ~/.vim/vimrc : on branche celui qui sert.
hook_vimrc() {
  if [ ! -e "$HOME/.vimrc" ] && [ -e "$HOME/.vim/vimrc" ]; then echo "$HOME/.vim/vimrc"; else echo "$HOME/.vimrc"; fi
}

# xrdb passe ~/.Xresources au préprocesseur C : un #include manquant ferait tout échouer, d'où __has_include.
_hook_xres_include() {
  printf '#if __has_include("%s") /* %s */\n#include "%s" /* %s */\n#endif /* %s */\n' "$1" "$HOOK_MARK" "$1" "$HOOK_MARK" "$HOOK_MARK"
}

hook_line() {
  if [ "$1" = tmux ]; then
    # Le format est répété : une ligne par fichier.
    printf "source-file -q '%s' # %s\n" "$DOTF/config/tmux/tmux.conf" "$HOOK_MARK" "$DOTF_LOCAL/tmux.conf" "$HOOK_MARK"
  elif [ "$1" = xres ]; then
    _hook_xres_include "$DOTF/config/x/Xresources"
    _hook_xres_include "$DOTF_LOCAL/Xresources"
  elif [ "$1" = vim ]; then
    printf "if filereadable('%s/config/vim/vimrc') | source %s/config/vim/vimrc | endif  \" %s\n" "$DOTF" "$DOTF" "$HOOK_MARK"
  else
    printf "if [ -r '%s/shell/%s.sh' ]; then DOTF='%s'; . '%s/shell/%s.sh'; fi  # %s\n" \
      "$DOTF" "$1" "$DOTF" "$DOTF" "$1" "$HOOK_MARK"
  fi
}

hook_present() { [ -f "$1" ] && grep -qF -- "$HOOK_MARK" "$1"; }

# Vrai si les lignes marquées du fichier sont exactement celles attendues.
hook_current() { [ -f "$1" ] && [ "$(grep -F -- "$HOOK_MARK" "$1")" = "$(hook_line "$2")" ]; }

# Réécrit le fichier en place : garde ses droits, et la cible s'il s'agit d'un lien.
hook_strip() {
  grep -vF -- "$HOOK_MARK" "$1" >"$1.dotf-tmp" || true
  cat "$1.dotf-tmp" >"$1"
  rm -f "$1.dotf-tmp"
}

hook_add() {
  if hook_current "$1" "$2"; then
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
  hook_line "$2" >>"$1"
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
  if [ -n "${DISPLAY-}" ] && command -v xrdb >/dev/null 2>&1 && [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources" && log_ok "ressources X rechargées (xrdb)"
  fi
}

# Tous les fichiers possibles, même ceux qui ne sont plus des cibles.
hooks_remove() {
  _z=${ZDOTDIR:-$HOME}
  for _f in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" "$_z/.zshenv" "$_z/.zshrc" "$HOME/.vimrc" "$HOME/.vim/vimrc" "$HOME/.Xresources" \
    "$HOME/.tmux.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"; do
    hook_remove "$_f"
  done
}

hooks_status() {
  for _t in $(hook_targets); do
    _f=${_t%:*}
    if hook_current "$_f" "${_t##*:}"; then
      log_ok "$(tilde "$_f")"
    elif hook_present "$_f"; then
      log_warn "$(tilde "$_f") : ligne obsolète, relancer « dotf install »"
    else
      log_warn "$(tilde "$_f") : non branché"
    fi
  done
}
