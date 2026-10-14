_dotf_title_precmd() { [[ -n $DOTF_TITLE ]] || _dotf_title "${HOST%%.*}: ${(%):-%~}"; }
_dotf_title_preexec() { [[ -n $DOTF_TITLE ]] || _dotf_title "${HOST%%.*}: $1"; }

autoload -Uz add-zsh-hook
add-zsh-hook precmd _dotf_title_precmd
add-zsh-hook preexec _dotf_title_preexec
