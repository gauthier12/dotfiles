# shellcheck shell=sh
# Environnement commun (sh POSIX), chargé par tous les shells. Peut être chargé plusieurs fois.

: "${DOTF:=$HOME/.local/share/dotf}"
: "${DOTF_LOCAL:=${XDG_CONFIG_HOME:-$HOME/.config}/dotf}"
export DOTF DOTF_LOCAL

# Ajoute un dossier en tête du PATH s'il existe et n'y est pas déjà.
dotf_path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

# zsh : un motif sans correspondance est une erreur ; on l'autorise le temps d'une boucle.
_dotf_glob_begin() {
  [ -n "${ZSH_VERSION-}" ] || return 0
  # shellcheck disable=SC3010
  if [[ -o null_glob ]]; then _dotf_ng_was_set=1; else _dotf_ng_was_set=; setopt null_glob; fi
}
_dotf_glob_end() {
  [ -n "${ZSH_VERSION-}" ] || return 0
  [ -n "$_dotf_ng_was_set" ] || unsetopt null_glob
  unset _dotf_ng_was_set
}

# zsh : compinit est lancé par rc.d/30-completion.zsh, pas par /etc/zsh/zshrc (Debian).
# shellcheck disable=SC2034
if [ -n "${ZSH_VERSION-}" ]; then skip_global_compinit=1; fi

dotf_path_prepend "$HOME/.cargo/bin"
dotf_path_prepend "$HOME/bin"
dotf_path_prepend "$HOME/.local/bin"
dotf_path_prepend "$DOTF/bin"
dotf_path_prepend "$DOTF_LOCAL/bin"
export PATH

if command -v vim >/dev/null 2>&1; then EDITOR='vim'; else EDITOR='vi'; fi
VISUAL=$EDITOR
export EDITOR VISUAL

# Config locale, puis profils (DOTF_PROFILES), puis env.d local.
if [ -r "$DOTF_LOCAL/config.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTF_LOCAL/config.sh"
fi

for _dotf_p in ${DOTF_PROFILES-}; do
  # shellcheck source=/dev/null
  if [ -r "$DOTF/profiles/$_dotf_p.sh" ]; then . "$DOTF/profiles/$_dotf_p.sh"; fi
done
unset _dotf_p

_dotf_glob_begin
for _dotf_f in "$DOTF_LOCAL"/env.d/*.sh; do
  # shellcheck source=/dev/null
  if [ -r "$_dotf_f" ]; then . "$_dotf_f"; fi
done
_dotf_glob_end
unset _dotf_f
