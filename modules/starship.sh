# shellcheck shell=sh disable=SC2034
# Prompt commun à bash et zsh. Config : $DOTF/config/starship.toml.

pkg_bins=starship
pkg_needs=catppuccin # palettes des couleurs du prompt

pkg_latest() { gh_latest starship/starship; }

pkg_install() {
  _f="starship-$(uname -m)-unknown-linux-musl.tar.gz"
  gh_get starship/starship "v$1" "$_f" "$_f.sha256" &&
    tar -xzf "$_f" starship && rm "$_f" || return 1
  ./starship completions bash | add_completion bash starship
  ./starship completions zsh | add_completion zsh starship
}
