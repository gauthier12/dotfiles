# shellcheck shell=sh
# Thème Catppuccin : mocha (sombre, par défaut) ou latte (clair), choisi par « dotf theme », ou LC_DOTF_THEME (transmis par ssh).
# La palette est envoyée au terminal (OSC 4, 10, 11, 12) au démarrage, puis au prompt qui suit un changement.
_dotf_theme() {
  DOTF_THEME=${LC_DOTF_THEME:-$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/dotf/theme" 2>/dev/null)}
  export DOTF_THEME="${DOTF_THEME:-mocha}"
  if [ "$DOTF_THEME" = "${_dotf_theme_sent-}" ] || [ ! -t 1 ] || [ "${TERM-}" = dumb ]; then return 0; fi
  _dotf_theme_sent=$DOTF_THEME
  sed -n -e 's/^\*color\([0-9]*\): *\(#[0-9a-f]*\).*/4;\1;\2/p' -e 's/^\*foreground: *\(#[0-9a-f]*\).*/10;\1/p' \
    -e 's/^\*background: *\(#[0-9a-f]*\).*/11;\1/p' -e 's/^\*cursorColor: *\(#[0-9a-f]*\).*/12;\1/p' \
    "$HOME/.local/opt/catppuccin/xresources/themes/$DOTF_THEME.Xresources" 2>/dev/null |
    while read -r _dotf_osc; do printf '\033]%s\007' "$_dotf_osc"; done
}
_dotf_theme
