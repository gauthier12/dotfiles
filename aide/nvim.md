# nvim : aides au développement (LSP)

nvim lit le même vimrc que vim (voir « dotf help vim ») ; en plus, il utilise des serveurs de langage :
    Rust     rust-analyzer (module rustup), vérifié par clippy
    Python   ty (module ty) : complétion, doc, définitions, types ; ruff (module ruff) : erreurs, imports, formatage
    Typst    tinymist (module tinymist), formatage par typstyle
Un serveur démarre seul à l'ouverture d'un fichier du langage, dans le projet (Cargo.toml, pyproject.toml, .git…).

## Complétion
Le menu s'ouvre pendant la frappe (Rust, Python, Typst). En Python, les bibliothèques sont celles du venv
actif ou du .venv du projet (« dotf help ty »).
    Ctrl-n / Ctrl-p              élément suivant / précédent (les flèches aussi)
    Ctrl-y                       accepter
    Ctrl-e                       fermer le menu
    Ctrl-x Ctrl-o                ouvrir le menu à la main
    Tab / Maj-Tab                champ suivant / précédent d'un modèle inséré (snippet)
    Ctrl-s                       en insertion : paramètres de la fonction appelée

## Comprendre et naviguer
    K                            documentation du symbole sous le curseur (K de nouveau : entrer dans la fenêtre)
    Ctrl-]                       aller à la définition ; Ctrl-t ou Ctrl-o pour revenir
    grr                          toutes les références (liste ; ]q [q pour les parcourir, :copen pour la voir)
    gri                          implémentations
    grt                          définition du type
    gO                           plan du fichier (fonctions, classes…)

## Modifier
    grn                          renommer le symbole partout (dans le projet)
    gra                          actions proposées : corriger, importer, retirer un import inutile…
    gq  (en visuel)              formater la sélection
    enregistrement               formatage automatique du fichier (:w)
    gcc  gc (en visuel)          commenter / décommenter

## Erreurs (diagnostics)
Affichées en fin de ligne, avec une icône dans la marge.
    ]d  [d                       erreur suivante / précédente
    ]D  [D                       dernière / première
    Ctrl-w d                     message complet de l'erreur sous le curseur
    :lua vim.diagnostic.setqflist()   toutes les erreurs dans une liste (:copen)

## Serveurs
    :checkhealth vim.lsp         serveurs actifs et problèmes éventuels
    :lsp restart                 relancer le serveur (après un changement de Cargo.toml…)
    :lsp stop  /  :lsp enable    arrêter / réactiver

## Exemples
    Python : un  import os  inutilisé est signalé en fin de ligne ; dessus, gra → « Remove unused import ».
             x: int = "a" est signalé par ty ; K sur une fonction → sa signature et sa docstring.
             gra → « Organize imports » trie les imports ; :w met le fichier en forme.
    Rust :   cargo new essai && cd essai && nvim src/main.rs
             sur une fonction : grn nouveau_nom Entrée → renommée dans tout le projet ; K sur println! → sa doc.
    Typst :  nvim rapport.typ ; :w reformate le fichier ; ]d va à la prochaine erreur de compilation.

Config : config/nvim/lsp.lua. Aide intégrée : :help lsp-quickstart, :help lsp-defaults.
