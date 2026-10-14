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

# Listes colorées comme ls (LS_COLORS), et kill <Tab> : menu de ses propres processus, PID en couleur.
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;34'

# Cache des complétions lentes (apt, dpkg, …).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_dotf_zcache/compcache"

unset _dotf_zcache
