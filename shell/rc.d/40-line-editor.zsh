# Édition de la ligne de commande (zsh).

# Ctrl-W, Alt-B, Alt-F… s'arrêtent aux / . - = : on efface ou saute un bout de chemin à la fois.
WORDCHARS=${WORDCHARS//[\/.=-]/}
