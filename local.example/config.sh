# Configuration propre à cette machine (hors git).
# Chargée par les shells (via shell/env.sh) et par la commande dotf.

# Modules optionnels à installer, séparés par des espaces (voir $DOTF/modules/) :
#   starship  prompt
#   gitleaks  détection de secrets pour le garde-fou (utile sur les machines où l'on commite)
# Après modification : « dotf install ». Un module retiré de la liste est désinstallé.
DOTF_MODULES="starship"
