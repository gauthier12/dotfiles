# dust : qu'est-ce qui prend de la place ?

Arbre des plus gros dossiers et fichiers, avec des barres proportionnelles. Les plus gros sont en bas.

## Commandes
    dust                         dossier courant
    dust ~/Téléchargements       un autre dossier
    dust -d 1                    un seul niveau de profondeur
    dust -n 40                   les 40 plus gros (par défaut : selon la hauteur du terminal)
    dust -r                      plus gros en haut
    dust -X .git -X target       en ignorant ces dossiers
    dust -s                      taille apparente (et non l'espace occupé sur le disque)
    dust -f                      nombre de fichiers au lieu de la taille
    dust -t                      par type de fichier (extension)
    dust -p                      chemins complets

## Exemples
    dust -d 1 ~                  quels dossiers du home sont les plus lourds
    dust -f -d 2 ~/.cache        où sont les milliers de petits fichiers
    dust -t ~/Images             combien pèsent les .jpg, .png, .mp4…
