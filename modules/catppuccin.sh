# shellcheck shell=sh disable=SC2034
# Thèmes Catppuccin : palette du terminal, zsh-syntax-highlighting, broot, gitui, lapce (vim : module vim-catppuccin).
# Pas de versions publiées : la version résume les commits des dépôts.

_ctp_repos="xresources zsh-syntax-highlighting broot gitui lapce"

pkg_latest() {
  for _r in $_ctp_repos; do git_head "https://github.com/catppuccin/$_r"; done | cksum | cut -d ' ' -f 1
}

pkg_install() {
  for _r in $_ctp_repos; do git clone -q --depth 1 "https://github.com/catppuccin/$_r" "$_r" || return 1; done
}
