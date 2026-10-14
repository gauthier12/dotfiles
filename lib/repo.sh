# shellcheck shell=sh
# Le clone git de dotf : URL de push, mise à jour, état.

repo_is_git() { [ -d "$DOTF/.git" ]; }

# DOTF_PUSH_URL (config locale) : pousser par une autre URL, ex. SSH.
repo_install() {
  repo_is_git || { log_info "pas un dépôt git, ignoré"; return 0; }
  _cur=$(git -C "$DOTF" config --get remote.origin.pushurl || true)
  if [ -n "${DOTF_PUSH_URL-}" ]; then
    if [ "$_cur" = "$DOTF_PUSH_URL" ]; then
      log_info "URL de push : $DOTF_PUSH_URL"
    else
      git -C "$DOTF" config remote.origin.pushurl "$DOTF_PUSH_URL"
      log_ok "URL de push : $DOTF_PUSH_URL"
    fi
  elif [ -n "$_cur" ]; then
    git -C "$DOTF" config --unset remote.origin.pushurl
    log_ok "URL de push spécifique retirée (DOTF_PUSH_URL vide)"
  else
    log_info "push par l'URL de récupération ($(git -C "$DOTF" config --get remote.origin.url || echo 'aucun remote'))"
  fi
}

repo_pull() {
  if ! git -C "$DOTF" diff --quiet || ! git -C "$DOTF" diff --cached --quiet; then
    die "modifications non commitées dans $(tilde "$DOTF") : les commiter ou les mettre de côté (git stash) d'abord"
  fi
  _old=$(git -C "$DOTF" rev-parse HEAD)
  git -C "$DOTF" pull --ff-only --quiet
  if [ "$(git -C "$DOTF" rev-parse HEAD)" = "$_old" ]; then
    log_info "déjà à jour"
  else
    git -C "$DOTF" log --oneline "$_old..HEAD" | sed 's/^/    /'
  fi
}

# Vrai s'il reste du travail non commité ou non poussé.
repo_dirty() {
  [ -n "$(git -C "$DOTF" status --porcelain 2>/dev/null)" ] ||
    [ -n "$(git -C "$DOTF" log --oneline '@{upstream}..HEAD' 2>/dev/null)" ]
}

repo_status() {
  _branch=$(git -C "$DOTF" symbolic-ref --short HEAD 2>/dev/null) || _branch='?'
  _commit=$(git -C "$DOTF" log -1 --format='%h %s' 2>/dev/null) || _commit='aucun'
  log_info "branche $_branch, commit $_commit"
  if [ -n "$(git -C "$DOTF" status --porcelain 2>/dev/null)" ]; then log_warn "modifications locales non commitées"; fi
  git -C "$DOTF" fetch --quiet 2>/dev/null || { log_info "dépôt distant injoignable"; return 0; }
  _ahead=$(git -C "$DOTF" rev-list --count '@{upstream}..HEAD' 2>/dev/null) || { log_info "pas de branche distante suivie"; return 0; }
  _behind=$(git -C "$DOTF" rev-list --count 'HEAD..@{upstream}')
  if [ "$_behind" -gt 0 ]; then log_warn "$_behind commit(s) à récupérer : « dotf update »"; fi
  if [ "$_ahead" -gt 0 ]; then log_warn "$_ahead commit(s) local(aux) non poussé(s)"; fi
  if [ "$_ahead$_behind" = 00 ]; then log_ok "à jour avec $(git -C "$DOTF" rev-parse --abbrev-ref '@{upstream}')"; fi
}
