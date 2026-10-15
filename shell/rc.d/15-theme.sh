# shellcheck shell=sh
# Thème Catppuccin (mocha par défaut, macchiato, frappe ou latte), choisi par « dotf theme ».

# Session ssh : on garde le thème du poste, reçu dans LC_DOTF_THEME (SendEnv de config/ssh/config).
if [ -n "${SSH_CONNECTION-}" ] && [ -n "${LC_DOTF_THEME-}" ] && [ -z "${DOTF_THEME_SSH-}" ]; then
  export DOTF_THEME_SSH="$LC_DOTF_THEME"
fi

_dotf_theme() {
  DOTF_THEME=${DOTF_THEME_SSH:-$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/dotf/theme" 2>/dev/null)}
  DOTF_THEME=${DOTF_THEME:-mocha}
  export DOTF_THEME LC_DOTF_THEME="$DOTF_THEME"
  # zsh : couleurs de la ligne de commande, rechargées quand le thème change.
  if [ -n "${ZSH_VERSION-}" ] && [ "$DOTF_THEME" != "${_dotf_theme_zsh-}" ]; then
    _dotf_theme_zsh=$DOTF_THEME
    _dotf_f=$HOME/.local/opt/catppuccin/zsh-syntax-highlighting/themes/catppuccin_$DOTF_THEME-zsh-syntax-highlighting.zsh
    # shellcheck source=/dev/null
    if [ -r "$_dotf_f" ]; then . "$_dotf_f"; fi
  fi
  # Palette (OSC 4, 10, 11, 12) renvoyée à chaque prompt : le terminal la retrouve après une session ssh, un reset…
  if [ ! -t 1 ] || [ "${TERM-}" = dumb ]; then return 0; fi
  sed -n -e 's/^\*color\([0-9]*\): *\(#[0-9a-f]*\).*/4;\1;\2/p' -e 's/^\*foreground: *\(#[0-9a-f]*\).*/10;\1/p' \
    -e 's/^\*background: *\(#[0-9a-f]*\).*/11;\1/p' -e 's/^\*cursorColor: *\(#[0-9a-f]*\).*/12;\1/p' \
    "$HOME/.local/opt/catppuccin/xresources/themes/$DOTF_THEME.Xresources" 2>/dev/null |
    while read -r _dotf_osc; do printf '\033]%s\007' "$_dotf_osc"; done
}
_dotf_theme
