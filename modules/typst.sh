# shellcheck shell=sh disable=SC2034
# Typst, composition de documents. Binaire statique (musl) ; la release ne publie pas de sommes.

pkg_bins=typst

pkg_latest() { gh_latest typst/typst; }

pkg_install() {
  _d="typst-$(uname -m)-unknown-linux-musl"
  gh_get typst/typst "v$1" "$_d.tar.xz" &&
    tar -xJf "$_d.tar.xz" --strip-components=1 "$_d/typst" && rm "$_d.tar.xz" || return 1
  ./typst completions bash | add_completion bash typst
  ./typst completions zsh | add_completion zsh typst
}
