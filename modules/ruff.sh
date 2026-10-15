# shellcheck shell=sh disable=SC2034
# ruff, linter et formateur Python (serveur de langage pour nvim : « ruff server »). Binaire musl vérifié.

pkg_bins=ruff

pkg_latest() { gh_latest astral-sh/ruff; }

pkg_install() {
  _d="ruff-$(uname -m)-unknown-linux-musl"
  gh_get astral-sh/ruff "$1" "$_d.tar.gz" "$_d.tar.gz.sha256" &&
    tar -xzf "$_d.tar.gz" --strip-components=1 "$_d/ruff" && rm "$_d.tar.gz" || return 1
  ./ruff generate-shell-completion bash | add_completion bash ruff
  ./ruff generate-shell-completion zsh | add_completion zsh ruff
}
