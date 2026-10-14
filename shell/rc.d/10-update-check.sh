# shellcheck shell=sh
# Signale les mises à jour de dotf. Fetch en arrière-plan une fois par jour au plus.
# DOTF_UPDATE_CHECK=0 pour désactiver.

if [ "${DOTF_UPDATE_CHECK-1}" != 0 ] && [ -d "$DOTF/.git" ]; then
  _dotf_behind=$(git -C "$DOTF" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || _dotf_behind=0
  if [ "${_dotf_behind:-0}" -gt 0 ]; then
    printf 'dotf : %s mise(s) à jour disponible(s), lancer « dotf update »\n' "$_dotf_behind"
  fi
  _dotf_stamp="${XDG_STATE_HOME:-$HOME/.local/state}/dotf/last-fetch"
  if [ -z "$(find "$_dotf_stamp" -mmin -1440 2>/dev/null)" ]; then
    mkdir -p "$(dirname "$_dotf_stamp")" && : >"$_dotf_stamp"
    # Détaché (pas de message de job), sans jamais demander d'identifiants.
    (GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes' git -C "$DOTF" fetch --quiet >/dev/null 2>&1 &)
  fi
  unset _dotf_behind _dotf_stamp
fi
