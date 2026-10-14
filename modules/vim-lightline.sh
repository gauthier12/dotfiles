# shellcheck shell=sh disable=SC2034
# Barre d'état vim, légère. Pas de version publiée : suit la branche principale.

pkg_latest() { git_head https://github.com/itchyny/lightline.vim; }

pkg_install() {
  git clone -q --depth 1 https://github.com/itchyny/lightline.vim . || return 1
  if command -v vim >/dev/null 2>&1; then vim -es -u NONE -c 'helptags doc' -c q; fi
}
