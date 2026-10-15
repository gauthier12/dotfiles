# shellcheck shell=sh disable=SC2034
# Neovim, archive officielle (x86_64, arm64). Utilise le vimrc commun (branchement de ~/.config/nvim).

pkg_bins=bin/nvim

pkg_latest() { gh_latest neovim/neovim; }

pkg_install() {
  case $(uname -m) in
    x86_64) _arch=x86_64 ;;
    aarch64) _arch=arm64 ;;
    *) return 1 ;;
  esac
  gh_get neovim/neovim "v$1" "nvim-linux-$_arch.tar.gz" &&
    tar -xzf "nvim-linux-$_arch.tar.gz" --strip-components=1 && rm "nvim-linux-$_arch.tar.gz" || return 1
  # Le binaire demande une glibc récente (2.34 et plus).
  ./bin/nvim --version >/dev/null 2>&1 || { log_warn "nvim : ne démarre pas sur ce système (glibc trop ancienne ?)"; return 1; }
}
