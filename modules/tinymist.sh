# shellcheck shell=sh disable=SC2034
# tinymist, serveur de langage Typst pour nvim (complétion, formatage typstyle, aperçu). Binaire musl vérifié.

pkg_bins=tinymist

pkg_latest() { gh_latest Myriad-Dreamin/tinymist; }

pkg_install() {
  _d="tinymist-$(uname -m)-unknown-linux-musl"
  gh_get Myriad-Dreamin/tinymist "v$1" "$_d.tar.gz" "$_d.tar.gz.sha256" &&
    tar -xzf "$_d.tar.gz" --strip-components=1 "$_d/tinymist" && rm "$_d.tar.gz" || return 1
  ./tinymist completion bash | add_completion bash tinymist
  ./tinymist completion zsh | add_completion zsh tinymist
}
