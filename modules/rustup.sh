# shellcheck shell=sh disable=SC2034,SC2016
# Rust (rustup, cargo, rustc), requis par les modules installés avec cargo.
# Emplacements standard de rustup : ~/.rustup et ~/.cargo. Une installation existante est reprise.

pkg_latest() { fetch https://static.rust-lang.org/rustup/release-stable.toml | sed -n "s/^version = '\(.*\)'/\1/p"; }

pkg_install() {
  _url="https://static.rust-lang.org/rustup/dist/$(uname -m)-unknown-linux-gnu/rustup-init"
  download "$_url" "$_url.sha256" && chmod +x rustup-init || return 1
  ./rustup-init -q -y --no-modify-path --profile minimal || return 1
  rm rustup-init
  # Pour les installations suivantes, avant que les shells n'aient ~/.cargo/bin.
  echo 'case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH" ;; esac' >.env.sh
}

pkg_update() { rustup -q self update >/dev/null && rustup -q update >/dev/null; }

# Supprime ~/.rustup et ~/.cargo, y compris ce qui a été installé à la main avec cargo.
pkg_remove() { "$HOME/.cargo/bin/rustup" -q self uninstall -y >/dev/null; }
