# shellcheck shell=sh disable=SC2034
# Suggestions grisées tirées de l'historique ; → ou Fin les accepte.

pkg_latest() { git_latest https://github.com/zsh-users/zsh-autosuggestions; }

pkg_install() { git clone -q --depth 1 --branch "$1" https://github.com/zsh-users/zsh-autosuggestions .; }
