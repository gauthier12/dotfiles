# Complétion : menu, insensible à la casse, mots partiels.

zmodload zsh/complist
autoload -Uz compinit

_dotf_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_dotf_zcache ]] || mkdir -p "$_dotf_zcache"

# -i : ignore sans demander les dossiers de fonctions non sûrs.
(( $+functions[compdef] )) || compinit -i -d "$_dotf_zcache/zcompdump-$ZSH_VERSION"

# Premier Tab : partie commune ; Tab suivant : menu.
setopt auto_menu complete_in_word always_to_end
unsetopt menu_complete
zstyle ':completion:*' menu select

# Essais successifs : exact, sans casse, par morceaux (f-b → foo-bar), n'importe où dans le nom.
zstyle ':completion:*' matcher-list '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*' \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

# Fichiers ignorés par la complétion (sauf s'il n'y a qu'eux).
fignore=(.o .old .bak "~" .pyc .class .swp .swo)

# cd : sous-dossiers, puis pile des dossiers.
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Couleurs de ls ; kill <Tab> : menu de ses processus.
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;34'

# Cache des complétions lentes (apt…).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_dotf_zcache/compcache"

unset _dotf_zcache
