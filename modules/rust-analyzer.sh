# shellcheck shell=sh disable=SC2034
# rust-analyzer (serveur de langage Rust pour nvim), avec rustfmt et clippy : composants rustup, la voie officielle.
# Mis à jour avec la chaîne Rust (« rustup update », module rustup).

pkg_needs=rustup

_ra_components="rust-analyzer rustfmt clippy"

pkg_latest() { echo stable; }

# shellcheck disable=SC2086
pkg_install() { rustup -q component add $_ra_components >/dev/null; }

# shellcheck disable=SC2086
pkg_remove() { rustup -q component remove $_ra_components >/dev/null; }
