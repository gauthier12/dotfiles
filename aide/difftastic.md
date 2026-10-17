# difftastic (difft) : diff qui comprend la syntaxe

Compare la structure du code, pas les lignes : un changement d'indentation ou un retour à la ligne
n'apparaît pas comme une modification.

## Commandes
    difft ancien.py nouveau.py   comparer deux fichiers (côte à côte)
    difft dossier1 dossier2      comparer deux dossiers
    difft --display inline a b   affichage sur une colonne (fenêtre étroite)
    difft --list-languages       langages reconnus

## Avec git (alias de dotf)
    git ddiff                    git diff, par difftastic
    git ddiff --staged           ce qui est prêt à être commité
    git dshow                    dernier commit ; git dshow <hash> pour un autre
    git dlog -p                  historique avec le diff de chaque commit
    git ddiff main -- src/       comparer à main, seulement dans src/

## Exemples
    Après un reformatage (ruff format, cargo fmt) : git ddiff ne montre que les vrais changements.
    git dlog -p -3 fichier.rs    les 3 derniers changements de ce fichier.
