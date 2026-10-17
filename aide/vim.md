# vim : l'essentiel, et ce que règle dotf

Modes : Normal (Échap), Insertion (i, a, o), Visuel (v, V, Ctrl-v), Commande (:).
Une commande = [nombre] action déplacement : d3w efface 3 mots, y$ copie jusqu'en fin de ligne.

## Se déplacer
    w b e                        mot suivant / précédent / fin du mot
    0 ^ $                        début / premier caractère / fin de ligne
    gg G 42G                     début / fin du fichier / ligne 42
    f x  ;                       aller au prochain « x » de la ligne, puis au suivant
    %                            parenthèse ou accolade correspondante
    * #                          mot sous le curseur, suivant / précédent
    Ctrl-o Ctrl-i                position précédente / suivante (après un saut)
    ma  'a                       poser la marque a, y revenir

## Modifier
    ciw  ci"  ci(  cit           remplacer le mot / le texte entre "" / () / la balise
    daw  dap                     effacer le mot / le paragraphe (avec l'espace)
    dd  yy  p  P                 couper / copier la ligne, coller après / avant
    .                            refaire la dernière modification
    u  Ctrl-r                    annuler / rétablir
    >>  <<                       indenter / désindenter (3 espaces)
    J                            joindre la ligne suivante
    ~                            changer la casse

## Rechercher, remplacer
    /motif  n  N                 chercher, suivant, précédent (sans casse ; Ctrl-l efface le surlignage en nvim)
    :%s/ancien/nouveau/g         remplacer partout
    :%s/ancien/nouveau/gc        idem, en demandant à chaque fois
    :s/a/b/g  (après V)          seulement dans la sélection

## Visuel
    v  V  Ctrl-v                 caractères / lignes / bloc
    Ctrl-v  3j  I// Échap        insérer « // » en tête de 4 lignes
    gv                           resélectionner

## Macros
    qa … q  puis  @a  10@a       enregistrer dans a, rejouer, rejouer 10 fois
    @@                           rejouer la dernière

## Fichiers, fenêtres
    :e fichier  :w  :q  :wq  :q! ouvrir / écrire / quitter / sans enregistrer
    :find nom<Tab>               trouver un fichier dans les sous-dossiers
    :Lex                         explorateur en arbre à gauche (netrw)
    :sp  :vs                     couper en haut-bas / gauche-droite (à droite par défaut)
    Ctrl-w h j k l               aller à la fenêtre voisine
    :tabe fichier  gt  gT        nouvel onglet, onglet suivant / précédent

## Réglages de dotf
    F9  F10                      numéros de ligne / numéros relatifs
    :Spellfr  :Spellen  :Spellno orthographe en français / anglais / arrêt
    ]s  [s  z=  zg               faute suivante / précédente, suggestions, ajouter le mot au dictionnaire
    souris                       active ; Maj + clic : sélection du terminal (copier vers une autre fenêtre)
    thème                        celui de « dotf theme », changé aussi dans les vim ouverts

## Exemples
    Renommer une variable dans le fichier : *  puis  :%s//nouveau/gc  (le motif vide reprend celui de *).
    Mettre une liste de lignes entre guillemets : qa I" Échap A", Échap j q  puis  10@a.
    Supprimer les lignes vides : :g/^$/d

Config : config/vim/vimrc ; pour la machine : ~/.config/dotf/vimrc. Aide intégrée : :help sujet, ou vimtutor.
