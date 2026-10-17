# typst : documents (rapports, articles, CV) en texte, compilés en PDF

## Commandes
    typst compile rapport.typ    produit rapport.pdf
    typst watch rapport.typ      recompile à chaque enregistrement (laisser tourner à côté de l'éditeur)
    typst watch rapport.typ --open        et ouvre le PDF (qui se recharge)
    typst compile rapport.typ page-{p}.png    une image PNG par page
    typst init @preview/charged-ieee       nouveau projet à partir d'un modèle (universe.typst.app)
    typst fonts                  polices disponibles

## Syntaxe de base
    = Titre   == Sous-titre      titres
    *gras*  _italique_  `code`   mise en forme
    - élément   + élément numéroté        listes
    $x^2 + y_1$                  maths dans la ligne ;  $ x^2 $ (avec espaces) : formule centrée
    #image("photo.png", width: 50%)       image
    #link("https://typst.app")[le site]   lien
    @fig1  <fig1>                renvoi, étiquette
    #table(columns: 2, [A], [B], [1], [2])    tableau
    // commentaire

## Réglages en tête de document
    #set page(paper: "a4", margin: 2cm)
    #set text(lang: "fr", font: "Libertinus Serif", size: 11pt)
    #set heading(numbering: "1.1")
    #outline()                   table des matières

## Exemple
    nvim rapport.typ  dans un volet,  typst watch rapport.typ --open  dans l'autre :
    chaque :w reformate (tinymist, voir « dotf help nvim ») et met le PDF à jour.
