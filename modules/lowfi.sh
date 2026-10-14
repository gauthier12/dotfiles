# shellcheck shell=sh disable=SC2034
# Lecteur de musique lo-fi. Méthode officielle : cargo install, dans ~/.cargo/bin.
# Compilation : il faut cc, pkg-config et les en-têtes ALSA et OpenSSL (paquets système).

pkg_needs=rustup

pkg_latest() { crate_latest lowfi; }

pkg_install() {
  if ! pkg-config --exists alsa openssl 2>/dev/null; then
    log_warn "lowfi : il manque pkg-config ou les en-têtes ALSA/OpenSSL (Debian : pkg-config libasound2-dev libssl-dev)"
    return 1
  fi
  cargo install -q lowfi --version "$1"
}

pkg_remove() { cargo uninstall -q lowfi; }
