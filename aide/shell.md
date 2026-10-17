# Shell (zsh, bash) : ligne de commande réglée par dotf

## Édition (mode vi)
La ligne s'édite comme dans vim : on tape en insertion (curseur barre), Échap passe en normal (curseur bloc).
    Échap puis b w 0 $ x cw …    déplacements et modifications de vim sur la ligne
    Échap puis v                 éditer la ligne dans vim (enregistrer et quitter : elle s'exécute)
    Ctrl-a / Ctrl-e              début / fin de ligne (en insertion)
    Ctrl-w / Ctrl-u              effacer le mot / le début de la ligne
    Ctrl-← / Ctrl-→              mot précédent / suivant
    Ctrl-l                       effacer l'écran

## Historique
    ↑ / ↓  (ou k / j en normal)  commandes qui commencent par ce qui est déjà tapé
    Ctrl-r                       chercher dans l'historique (Ctrl-r encore : plus ancien)
    history | tail -20           les 20 dernières commandes (datées en zsh)
     commande                    une espace devant : non enregistrée (mot de passe en argument…)
zsh partage l'historique entre les terminaux ouverts.

## Suggestions (zsh)
Une suite grisée est proposée d'après l'historique.
    →  ou  Fin                   accepter la suggestion
    Ctrl-→                       en accepter un seul mot

## Complétion
    Tab                          compléter ; Tab encore : menu, à parcourir avec les flèches
    Maj-Tab                      élément précédent
    cd f-b<Tab>                  morceaux de noms : f-b → foo-bar ; la casse est ignorée
    kill <Tab>                   menu de ses processus

## Dossiers
    -                            retour au dossier précédent
    d                            pile des derniers dossiers, numérotés (zsh)
    1 … 9                        retourner au dossier de ce numéro (zsh)
    br                           broot : choisir un dossier, y aller en quittant (voir « dotf help broot »)

## Tâches
    Ctrl-z                       suspendre le programme (vim…) ; Ctrl-z sur la ligne vide : le reprendre (zsh)

## Prompt (starship)
Heure, utilisateur, machine (couleur propre à chacune), dossier, branche git ; à droite : durée et code retour.
    starship explain             ce qu'affiche chaque partie du prompt
    starship timings             ce qui ralentit le prompt

## Exemples
    git log --oneline | head  puis ↑ : les lignes commençant par « git » seulement.
    zmv '(*).jpeg' '$1.jpg'      renommer tous les .jpeg en .jpg (zsh)
    cd /etc ; cd ~/projets ; d   puis  2  : retour dans /etc.

Réglages : shell/rc.d ; pour la machine : ~/.config/dotf/ (dotf edit).
