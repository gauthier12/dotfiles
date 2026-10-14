# Ligne de commande en mode vi.

bindkey -v
KEYTIMEOUT=1 # délai après Échap : 10 ms

# Les mots s'arrêtent aux / . - =
WORDCHARS=${WORDCHARS//[\/.=-]/}

# Les codes terminfo des touches ne valent qu'en mode « application » du terminal.
autoload -Uz add-zle-hook-widget
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  _dotf_keypad_on() { echoti smkx; }
  _dotf_keypad_off() { echoti rmkx; }
  add-zle-hook-widget line-init _dotf_keypad_on
  add-zle-hook-widget line-finish _dotf_keypad_off
fi

# Curseur : barre en insertion, bloc en normal.
if [[ $TERM != (dumb|linux) ]]; then
  _dotf_cursor_shape() {
    if [[ $KEYMAP == vicmd ]]; then print -n '\e[2 q'; else print -n '\e[6 q'; fi
  }
  _dotf_cursor_reset() { print -n '\e[0 q'; } # pour les programmes lancés
  add-zle-hook-widget line-init _dotf_cursor_shape
  add-zle-hook-widget keymap-select _dotf_cursor_shape
  add-zle-hook-widget line-finish _dotf_cursor_reset
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line

# _dotf_bind <capacité terminfo> <séquence si absente> <widget> <keymaps…>
_dotf_bind() {
  local seq=${terminfo[$1]:-$2} map
  [[ -n $seq ]] || return 0
  for map in "${@:4}"; do bindkey -M "$map" -- "$seq" "$3"; done
}
_dotf_bind khome '^[[H'    beginning-of-line                viins vicmd
_dotf_bind kend  '^[[F'    end-of-line                      viins vicmd
_dotf_bind kdch1 '^[[3~'   delete-char                      viins vicmd
_dotf_bind kich1 '^[[2~'   overwrite-mode                   viins
_dotf_bind kpp   '^[[5~'   beginning-of-buffer-or-history   viins vicmd
_dotf_bind knp   '^[[6~'   end-of-buffer-or-history         viins vicmd
_dotf_bind kcbt  '^[[Z'    reverse-menu-complete            viins menuselect
_dotf_bind kLFT5 '^[[1;5D' backward-word                    viins vicmd
_dotf_bind kRIT5 '^[[1;5C' forward-word                     viins vicmd
# ↑ ↓, k j : historique filtré par le début de la ligne.
_dotf_bind kcuu1 '^[[A'    up-line-or-beginning-search      viins vicmd
_dotf_bind kcud1 '^[[B'    down-line-or-beginning-search    viins vicmd
unfunction _dotf_bind
bindkey -M vicmd k up-line-or-beginning-search
bindkey -M vicmd j down-line-or-beginning-search

# Insertion : effacement sans la limite du vi strict, raccourcis usuels.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^S' history-incremental-search-forward
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line

# Édite la ligne dans $EDITOR.
bindkey -M vicmd v edit-command-line
bindkey -M viins '^X^E' edit-command-line
