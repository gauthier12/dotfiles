# tmux : sessions qui survivent à la déconnexion, fenêtres et volets

Préfixe : Ctrl-b, puis la touche (noté « P x » ci-dessous). Souris active : clic pour choisir un volet,
glisser une bordure pour redimensionner, molette pour remonter l'historique. Maj + glisser : sélection du terminal.

## Sessions
    tmux                         nouvelle session
    tmux new -s travail          nouvelle session nommée
    tmux ls                      liste des sessions
    tmux a -t travail            se rattacher à une session
    tmux new -A -s main          se rattacher à « main », ou la créer
    P d                          se détacher (la session continue)
    P s                          choisir une session dans la liste
    P $                          renommer la session

## Fenêtres (onglets en bas)
    P c                          nouvelle fenêtre
    P n / P p                    fenêtre suivante / précédente
    P 0 … P 9                    aller à la fenêtre n°
    P ,                          renommer la fenêtre
    P w                          arbre des sessions et fenêtres
    P &                          fermer la fenêtre

## Volets (découpage)
    P %                          couper en gauche | droite
    P "                          couper en haut / bas
    P ←↑→↓                       aller au volet voisin
    P o                          volet suivant
    P z                          agrandir / rétablir le volet
    P Ctrl-←↑→↓                  redimensionner
    P Espace                     disposition suivante
    P !                          sortir le volet dans sa propre fenêtre
    P x                          fermer le volet

## Copier (mode copie, touches vi)
    P [                          entrer (ou molette vers le haut)
    /motif   n                   chercher, occurrence suivante
    Espace … Entrée              début de sélection … copier et sortir
    P ]                          coller
    q                            sortir

## Divers
    P ?                          tous les raccourcis
    P :                          commande tmux (ex. :setw synchronize-panes on)

## Exemples
    ssh serveur -t tmux new -A -s main
        travail distant qui survit à une coupure : relancer la même commande pour reprendre.
    P %  puis  htop  dans un volet, et le shell dans l'autre ; P z pour agrandir le shell.
    P :setw synchronize-panes on
        la frappe va dans tous les volets de la fenêtre (même commande sur plusieurs ssh) ; « off » pour arrêter.

Config : config/tmux/tmux.conf ; pour la machine : ~/.config/dotf/tmux.conf.
