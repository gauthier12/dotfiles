# shellcheck shell=sh disable=SC2034
# Thème vim Catppuccin (avec ses thèmes lightline). Pas de version publiée : suit la branche principale.

pkg_latest() { git_head https://github.com/catppuccin/vim; }

pkg_install() { git clone -q --depth 1 https://github.com/catppuccin/vim .; }
