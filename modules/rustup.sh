# shellcheck shell=sh disable=SC2034,SC2016
# Rust (rustup, cargo, rustc), requis par les modules installés avec cargo.
# Méthode officielle (sh.rustup.rs), emplacements standard ~/.rustup et ~/.cargo. Une installation existante est reprise.

pkg_latest() { fetch https://static.rust-lang.org/rustup/release-stable.toml | sed -n "s/^version = '\(.*\)'/\1/p"; }

pkg_install() {
  fetch https://sh.rustup.rs >rustup.sh || return 1
  sh rustup.sh -q -y --no-modify-path --profile minimal >/dev/null || return 1
  rm rustup.sh
  _rustup_completions
  # Pour les installations suivantes, avant que les shells n'aient ~/.cargo/bin.
  echo 'case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH" ;; esac' >.env.sh
}

pkg_update() { rustup -q self update >/dev/null && rustup -q update >/dev/null && _rustup_completions; }

_rustup_completions() {
  for _sh in bash zsh; do
    for _c in rustup cargo; do "$HOME/.cargo/bin/rustup" completions "$_sh" "$_c" | add_completion "$_sh" "$_c"; done
  done
}

# Supprime ~/.rustup et ~/.cargo, y compris ce qui a été installé à la main avec cargo.
pkg_remove() { "$HOME/.cargo/bin/rustup" -q self uninstall -y >/dev/null; }
