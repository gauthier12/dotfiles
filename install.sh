#!/bin/sh
# Bootstrap dotf. Deux façons de l'utiliser :
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/gauthier12/dotfiles/main/install.sh)"
#   ./install.sh            (depuis un clone existant)
# Variables possibles : DOTF (emplacement du dépôt), DOTF_REPO, DOTF_BRANCH.
set -eu

DOTF_REPO=${DOTF_REPO:-https://github.com/gauthier12/dotfiles.git}
DOTF_BRANCH=${DOTF_BRANCH:-main}

die() { printf 'dotf: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git est requis"

# Lancé depuis un clone : on utilise ce clone tel quel.
_here=
case $0 in
  */install.sh | install.sh) _here=$(cd "$(dirname "$0")" && pwd -P) ;;
esac

if [ -n "$_here" ] && [ -x "$_here/bin/dotf" ]; then
  DOTF=$_here
else
  DOTF=${DOTF:-$HOME/.local/share/dotf}
  if [ -d "$DOTF/.git" ]; then
    echo "Dépôt déjà présent dans $DOTF"
  else
    echo "Clonage de $DOTF_REPO dans $DOTF"
    mkdir -p "$(dirname "$DOTF")"
    git clone --quiet --branch "$DOTF_BRANCH" "$DOTF_REPO" "$DOTF"
  fi
fi

exec "$DOTF/bin/dotf" install
