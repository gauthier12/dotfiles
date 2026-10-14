# shellcheck shell=sh disable=SC2034
# du lisible. Méthode officielle : son script d'installation, dirigé vers le dossier du module.

pkg_bins=dust

pkg_latest() { gh_latest bootandy/dust; }

pkg_install() {
  fetch https://raw.githubusercontent.com/bootandy/dust/refs/heads/master/install.sh >install.sh || return 1
  DUST_INSTALL="$PWD" sh install.sh >/dev/null || return 1
  rm install.sh
  for _f in dust.bash:bash _dust:zsh; do
    fetch "https://raw.githubusercontent.com/bootandy/dust/v$1/completions/${_f%:*}" | add_completion "${_f#*:}" dust
  done
}
