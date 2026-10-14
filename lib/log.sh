# shellcheck shell=sh
# Messages de l'installateur.

# shellcheck disable=SC2034 # utilisé par links.sh et scan.sh
TAB=$(printf '\t')

if [ -t 1 ]; then
  _c_ok=$(printf '\033[32m') _c_warn=$(printf '\033[33m') _c_err=$(printf '\033[31m') _c_dim=$(printf '\033[2m') _c_off=$(printf '\033[0m')
else
  _c_ok='' _c_warn='' _c_err='' _c_dim='' _c_off=''
fi

log_step() { printf '%s==>%s %s\n' "$_c_dim" "$_c_off" "$*"; }
log_ok()   { printf '  %s✓%s %s\n' "$_c_ok" "$_c_off" "$*"; }
log_info() { printf '  %s·%s %s\n' "$_c_dim" "$_c_off" "$*"; }
log_warn() { printf '  %s!%s %s\n' "$_c_warn" "$_c_off" "$*" >&2; }
die()      { printf '%sdotf:%s %s\n' "$_c_err" "$_c_off" "$*" >&2; exit 1; }

# Affiche un chemin avec ~ à la place de $HOME.
# shellcheck disable=SC2088 # ~ affiché, pas développé
tilde() {
  case $1 in
    "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}
