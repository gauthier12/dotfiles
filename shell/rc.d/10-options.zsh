# Options générales de zsh.

setopt interactive_comments # « # commentaire » accepté dans une commande tapée
setopt no_beep

# zmv : renommage en masse, ex. zmv '(*).jpeg' '$1.jpg'
autoload -Uz zmv
