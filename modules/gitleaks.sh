# shellcheck shell=sh disable=SC2034
# Détection de secrets, utilisée par le garde-fou (dotf scan).

pkg_bins=gitleaks

pkg_latest() { gh_latest gitleaks/gitleaks; }

pkg_install() {
  case $(uname -m) in
    x86_64) _arch=x64 ;;
    aarch64) _arch=arm64 ;;
    *) return 1 ;;
  esac
  _f="gitleaks_$1_linux_$_arch.tar.gz"
  gh_get gitleaks/gitleaks "v$1" "$_f" "gitleaks_$1_checksums.txt" &&
    tar -xzf "$_f" gitleaks && rm "$_f"
}
