# shellcheck shell=sh
# Home sur le réseau (NFS) : les caches vont sur le disque local, bien plus rapide.

export XDG_CACHE_HOME="${TMPDIR:-/tmp}/${USER:-$(id -un)}/.cache"
[ -d "$XDG_CACHE_HOME" ] || mkdir -p "$XDG_CACHE_HOME"
