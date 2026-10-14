# shellcheck shell=sh
# Modules optionnels : modules/<nom>.sh, activés par machine via DOTF_MODULES
# dans ~/.config/dotf/config.sh.
#
# Un module définit :
#   mod_installed  vrai si le module est en place
#   mod_install    installe (n'est appelé que si mod_installed est faux)
#   mod_update     met à jour
#   mod_remove     désinstalle
# Chaque appel tourne dans un sous-shell : les modules ne se marchent pas dessus.

# Télécharge une URL sur la sortie standard, avec curl ou wget.
fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    log_warn "ni curl ni wget disponible"
    return 1
  fi
}

module_available() { [ -r "$DOTF/modules/$1.sh" ]; }

module_call() {
  (
    # shellcheck disable=SC1090
    . "$DOTF/modules/$1.sh"
    "mod_$2"
  )
}

module_sync() {
  _update=${1-}
  # Modules installés par dotf mais retirés de DOTF_MODULES
  for _m in $(state_list modules); do
    case " ${DOTF_MODULES-} " in *" $_m "*) continue ;; esac
    if module_available "$_m" && module_call "$_m" remove; then
      log_ok "module $_m : désinstallé"
    else
      log_warn "module $_m : désinstallation impossible"
    fi
    state_del modules "$_m"
  done
  for _m in ${DOTF_MODULES-}; do
    if ! module_available "$_m"; then
      log_warn "module $_m : inconnu (pas de modules/$_m.sh)"
      continue
    fi
    if module_call "$_m" installed; then
      if [ -n "$_update" ]; then
        if module_call "$_m" update; then log_ok "module $_m : à jour"; else log_warn "module $_m : échec de la mise à jour"; fi
      else
        log_info "module $_m : déjà installé"
      fi
    elif module_call "$_m" install; then
      log_ok "module $_m : installé"
    else
      log_warn "module $_m : échec de l'installation"
      continue
    fi
    state_add modules "$_m"
  done
}

module_remove_all() {
  for _m in $(state_list modules); do
    if module_available "$_m" && module_call "$_m" remove; then
      log_ok "module $_m : désinstallé"
    else
      log_warn "module $_m : désinstallation impossible"
    fi
    state_del modules "$_m"
  done
}

module_status() {
  for _f in "$DOTF"/modules/*.sh; do
    [ -r "$_f" ] || continue
    _m=$(basename "$_f" .sh)
    _active=inactif
    case " ${DOTF_MODULES-} " in *" $_m "*) _active=actif ;; esac
    if module_call "$_m" installed; then
      log_ok "$_m ($_active, installé)"
    elif [ "$_active" = actif ]; then
      log_warn "$_m (actif, NON installé : lancer « dotf install »)"
    else
      log_info "$_m ($_active)"
    fi
  done
}
