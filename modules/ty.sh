# shellcheck shell=sh disable=SC2034
# ty, vérificateur de types Python ; serveur de langage pour nvim (« ty server ») : complétion, doc, définitions. Binaire musl vérifié.

pkg_bins=ty

pkg_latest() { gh_latest astral-sh/ty; }

pkg_install() {
  _d="ty-$(uname -m)-unknown-linux-musl"
  gh_get astral-sh/ty "$1" "$_d.tar.gz" "$_d.tar.gz.sha256" &&
    tar -xzf "$_d.tar.gz" --strip-components=1 "$_d/ty" && rm "$_d.tar.gz" || return 1
  ./ty generate-shell-completion bash | add_completion bash ty
  ./ty generate-shell-completion zsh | add_completion zsh ty
}
