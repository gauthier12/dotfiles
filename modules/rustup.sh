# shellcheck shell=sh disable=SC2034
# Rust (rustup, cargo, rustc), requis par les modules installés avec cargo.
# Tout est dans ~/.local/opt/rustup : RUSTUP_HOME et CARGO_HOME y pointent (.env.sh).

pkg_latest() { fetch https://static.rust-lang.org/rustup/release-stable.toml | sed -n "s/^version = '\(.*\)'/\1/p"; }

pkg_install() {
  _url="https://static.rust-lang.org/rustup/dist/$(uname -m)-unknown-linux-gnu/rustup-init"
  download "$_url" "$_url.sha256" && chmod +x rustup-init || return 1
  RUSTUP_HOME="$PWD/rustup" CARGO_HOME="$PWD/cargo" ./rustup-init -q -y --no-modify-path --profile minimal || return 1
  rm rustup-init
  _dir="$DOTF_OPT/rustup"
  cat >.env.sh <<ENV
export RUSTUP_HOME="$_dir/rustup" CARGO_HOME="$_dir/cargo"
case ":\$PATH:" in *":$_dir/cargo/bin:"*) ;; *) PATH="$_dir/cargo/bin:\$PATH" ;; esac
ENV
}

pkg_update() { rustup -q self update >/dev/null && rustup -q update >/dev/null; }
