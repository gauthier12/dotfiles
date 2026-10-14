# shellcheck shell=sh
# Config git : une ligne include.path dans ~/.gitconfig vers $DOTF/config/git/config.

GIT_INCLUDE="$DOTF/config/git/config"

_git_included() { git config --global --get-all include.path 2>/dev/null | grep -qxF -- "$GIT_INCLUDE"; }

git_install() {
  command -v git >/dev/null 2>&1 || { log_info "git absent, ignoré"; return 0; }
  if _git_included; then
    log_info "$(tilde "$HOME/.gitconfig") : déjà inclus"
    return 0
  fi
  [ -e "$HOME/.gitconfig" ] || [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/git/config" ] || state_add created "$HOME/.gitconfig"
  git config --global --add include.path "$GIT_INCLUDE"
  log_ok "$(tilde "$HOME/.gitconfig") : inclut $(tilde "$GIT_INCLUDE")"
}

git_remove() {
  _git_included || return 0
  git config --global --fixed-value --unset-all include.path "$GIT_INCLUDE"
  # Créé par dotf et vide désormais : supprimé.
  if state_has created "$HOME/.gitconfig" && [ -z "$(git config --global --list 2>/dev/null)" ]; then
    rm -f "$HOME/.gitconfig"
  fi
  state_del created "$HOME/.gitconfig"
  log_ok "$(tilde "$HOME/.gitconfig") : inclusion retirée"
}

git_status() {
  if _git_included; then log_ok "$(tilde "$HOME/.gitconfig") inclut la config du dépôt"; else log_warn "config git non incluse : relancer « dotf install »"; fi
  log_info "identité : $(git config --global --includes user.name || echo '?') <$(git config --global --includes user.email || echo '?')>"
}
