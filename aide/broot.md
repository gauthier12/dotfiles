# broot : parcourir une arborescence, chercher, agir sur les fichiers

Lancer avec br (pas broot) : en quittant sur un dossier, le shell y va.
On tape directement pour filtrer ; les commandes (« verbes ») commencent par un espace ou « : ».

## Se déplacer
    taper un motif               filtrer les noms (approximatif : « cfgk » trouve config/kitty)
    ↑ ↓   Tab / Maj-Tab          ligne précédente / suivante, résultat suivant / précédent
    Entrée                       entrer dans le dossier, ou ouvrir le fichier (application du système)
    Alt-Entrée                   aller dans le dossier choisi et quitter (avec br)
    Ctrl-← / Ctrl-→              panneau à gauche / aperçu ou panneau à droite
    Échap                        effacer le filtre, revenir en arrière
    Ctrl-q  ou  :q               quitter

## Filtres
    motif                        nom approché
    /regex                       nom par expression régulière (ex. /\.rs$)
    c/texte                      fichiers qui contiennent « texte »
    motif&c/texte                les deux à la fois

## Affichage
    Alt-h                        fichiers cachés
    Alt-i                        fichiers ignorés par git
    Alt-g  ou  :gs               état git des fichiers
    :sizes                       tailles (dossiers compris) ; :ss trie par taille
    :dates   :sd                 dates ; trier par date
    F5                           rafraîchir

## Agir sur le fichier choisi
    Ctrl-e  ou  :e               éditer dans vim
    :rm                          supprimer
    :mv nouveau_nom              renommer, déplacer
    :cp destination              copier
    :md nom                      créer un dossier
    :create nom                  créer un fichier et l'éditer
    Ctrl-t                       shell dans ce dossier (exit pour revenir)
    + / -                        ajouter / retirer de la sélection multiple, puis un verbe s'applique à tous
    ?  ou  F1                    aide : tous les verbes et touches

## Exemples
    br -s ~                      où partent les gigaoctets : tailles de chaque dossier
    br  puis  c/TODO             tous les fichiers qui contiennent TODO ; Ctrl-→ pour les lire
    br  puis  proj  Alt-Entrée   aller dans ~/projets sans taper le chemin

Couleurs : celles de « dotf theme ».
