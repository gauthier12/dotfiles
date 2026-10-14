# shellcheck shell=sh disable=SC2034
# Colore la commande pendant la frappe.

pkg_latest() { git_latest https://github.com/zsh-users/zsh-syntax-highlighting; }

pkg_install() { git -c advice.detachedHead=false clone -q --depth 1 --branch "$1" https://github.com/zsh-users/zsh-syntax-highlighting .; }
