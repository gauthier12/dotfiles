# gitui : git en plein écran, au clavier

Lancer gitui dans un dépôt. La barre du bas montre les touches utiles à l'endroit où l'on est ; h : aide complète.

## Onglets
    1 Status  2 Log  3 Files  4 Stashing  5 Stashes      (Tab / Maj-Tab pour passer de l'un à l'autre)
    ← →                          passer d'une colonne à l'autre (fichiers / diff)
    q  ou  Ctrl-c                quitter ;  Échap : fermer la fenêtre ouverte

## Status : préparer et commiter
    Entrée                       ajouter / retirer le fichier (git add / git restore --staged)
    a                            tout ajouter
    s  (dans le diff)            ajouter seulement le bloc ou les lignes sélectionnés (Maj-↑↓ pour sélectionner)
    d  (dans le diff)            annuler ces lignes
    D                            annuler les modifications du fichier
    i                            ignorer le fichier (.gitignore)
    e                            éditer le fichier
    c                            écrire le message de commit ; Ctrl-d valide (Entrée : nouvelle ligne)
    Ctrl-a  (dans le message)    modifier le dernier commit (amend)

## Branches et serveur
    b                            branches : Entrée pour basculer, c créer, r renommer, D supprimer, m fusionner
    p / P                        push / push forcé
    f / F                        pull / fetch
    Maj-U                        défaire le dernier commit (les modifications restent)

## Log
    Entrée                       détail du commit
    Espace                       marquer ; Maj-C : comparer deux commits marqués
    t                            poser un tag ; Maj-T : liste des tags
    y                            copier le hash
    Ctrl-j                       aller au commit d'un hash

## Fichiers
    Maj-B                        blame (qui a écrit chaque ligne)
    Maj-H                        historique du fichier
    f                            chercher un fichier

## Stash
    4 puis s                     mettre de côté (u : avec les fichiers non suivis)
    5 puis a / D                 réappliquer / supprimer

## Exemples
    Commiter une partie d'un fichier : 1, choisir le fichier, →, Maj-↓ sur les lignes, s, puis c.
    Changer de branche proprement : 4 s (stash), b, choisir, Entrée, puis 5 a.

Couleurs : celles de « dotf theme ».
