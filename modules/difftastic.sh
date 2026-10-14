# shellcheck shell=sh disable=SC2034
# Diff qui comprend la syntaxe (commande difft). Méthode officielle : binaires précompilés.

pkg_bins=difft

pkg_latest() { gh_latest Wilfred/difftastic; }

pkg_install() {
  # Version musl (autonome) seulement pour x86_64.
  _libc=gnu
  if [ "$(uname -m)" = x86_64 ]; then _libc=musl; fi
  _f="difft-$1-$(uname -m)-unknown-linux-$_libc.tar.gz"
  gh_get Wilfred/difftastic "$1" "$_f" && tar -xzf "$_f" difft && rm "$_f"
}
