# shellcheck shell=sh disable=SC2034
# Barre d'état vim. Son thème vient du thème de couleurs (onedark en fournit un).

pkg_latest() { git_latest https://github.com/vim-airline/vim-airline; }

pkg_install() {
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$1" https://github.com/vim-airline/vim-airline . || return 1
  if command -v vim >/dev/null 2>&1; then vim -es -u NONE -c 'helptags doc' -c q; fi
}
