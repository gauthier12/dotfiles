# Complétion zsh : menu navigable, insensible à la casse, complétion de mots partiels.

zmodload zsh/complist
autoload -Uz compinit

_dotf_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_dotf_zcache ]] || mkdir -p "$_dotf_zcache"

# Sauf si un fichier système l'a déjà fait. -i : ignore sans rien demander les dossiers de
# fonctions modifiables par d'autres utilisateurs.
(( $+functions[compdef] )) || compinit -i -d "$_dotf_zcache/zcompdump-$ZSH_VERSION"

# Premier Tab : complète ce qui est commun ; Tab suivant : menu, parcouru avec Tab ou les flèches.
setopt auto_menu complete_in_word always_to_end
unsetopt menu_complete
zstyle ':completion:*' menu select

# Essais successifs : exact, puis sans tenir compte de la casse, puis par morceaux autour
# de . _ - (f-b → foo-bar), puis n'importe où dans le nom.
zstyle ':completion:*' matcher-list '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*' \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

# cd : sous-dossiers du dossier courant d'abord, puis la pile des dossiers, puis $cdpath.
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Cache des complétions lentes (apt, dpkg, …).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_dotf_zcache/compcache"

unset _dotf_zcache
