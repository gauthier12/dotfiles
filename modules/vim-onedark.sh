# shellcheck shell=sh disable=SC2034
# Thème vim onedark (avec son thème lightline). Pas de version publiée : suit la branche principale.

pkg_latest() { git_head https://github.com/joshdick/onedark.vim; }

pkg_install() { git clone -q --depth 1 https://github.com/joshdick/onedark.vim .; }
