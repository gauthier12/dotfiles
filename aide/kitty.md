# kitty : onglets, fenêtres découpées, sélection au clavier

Tous les raccourcis commencent par Ctrl+Maj (noté « K+ »). Une « fenêtre » kitty est un volet dans l'onglet.

## Copier, coller, défiler
    K+c / K+v                    copier / coller
    K+s                          coller la sélection (comme le clic du milieu)
    K+↑ / K+↓  (ou K+k / K+j)    défiler d'une ligne
    K+PgPréc / K+PgSuiv          défiler d'une page
    K+Début / K+Fin              haut / bas de l'historique
    K+h                          historique entier dans un pager (less : /motif pour chercher)
    K+/                          chercher dans l'historique

## Prompts (intégration shell)
    K+z / K+x                    remonter au prompt précédent / suivant
    K+g                          sortie de la dernière commande dans un pager

## Onglets
    K+t                          nouvel onglet
    K+→ / K+←  (ou Ctrl+Tab)     onglet suivant / précédent
    K+. / K+,                    déplacer l'onglet
    K+Alt+t                      renommer l'onglet
    K+q                          fermer l'onglet

## Fenêtres (volets dans l'onglet)
    K+Entrée                     nouvelle fenêtre
    K+l                          disposition suivante (tall, fat, grid, horizontal, vertical, splits, stack)
    K+] / K+[                    fenêtre suivante / précédente
    K+1 … K+0                    aller à la fenêtre n°
    K+F7                         montrer les numéros, puis taper celui à activer
    K+F8                         échanger avec une autre fenêtre
    K+f / K+b                    déplacer la fenêtre
    K+r                          redimensionner (puis w, n, t, s ; Échap pour finir)
    K+w                          fermer la fenêtre
    K+n                          nouvelle fenêtre système (nouvelle instance)

## Repérer et réutiliser ce qui est à l'écran (« hints »)
    K+e                          ouvrir une URL affichée (taper la lettre qui apparaît)
    K+p puis f                   insérer un chemin affiché dans la ligne de commande
    K+p puis Maj+f               ouvrir un chemin affiché
    K+p puis n                   ouvrir « fichier:ligne » dans vim, à la ligne (nouvelle fenêtre)
    K+p puis l / w / h           insérer une ligne / un mot / un hash (git) affiché
    K+p puis c / d               choisir un fichier / un dossier et l'insérer

## Police, écran, config
    K+= / K+- / K+Retour arr.    agrandir / réduire / taille d'origine
    K+F11 / K+F10                plein écran / maximiser
    K+u                          saisir un caractère Unicode par son nom (ex. « arrow »)
    K+Suppr                      effacer et réinitialiser le terminal
    K+F3                         palette des commandes (toutes les actions, avec leur raccourci)
    K+F5                         relire la config
    K+F1                         documentation

## Kittens (commandes)
    kitten icat photo.png        afficher une image dans le terminal
    kitten diff a.py b.py        diff côte à côte, coloré (images aussi)
    kitten ssh serveur           ssh avec l'intégration shell et le terminfo de kitty

## Exemples
    grep -rn TODO .      puis K+p n      ouvre le TODO choisi dans vim, à sa ligne.
    git log --oneline    puis K+p h      insère le hash choisi : git show <hash>.
    cargo build (long)   puis K+g        relire toute la sortie de la commande.

Couleurs : celles de « dotf theme ». Réglages de la machine : ~/.config/dotf/kitty.conf (relu avec K+F5).
