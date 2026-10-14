# Configuration propre à cette machine (hors git).
# Chargée par les shells (via shell/env.sh) et par la commande dotf.

# Modules optionnels à installer, séparés par des espaces (voir $DOTF/modules/) :
#   starship  prompt
#   gitleaks  détection de secrets pour le garde-fou (utile sur les machines où l'on commite)
#   joplin    application de notes Joplin (bureau), commande « joplin »
#   zsh-autosuggestions, zsh-syntax-highlighting
#   broot, difftastic (difft), dust, gitui
#   lowfi     compilé avec cargo (rustup installé avant) ; demande pkg-config et les en-têtes ALSA/OpenSSL
# Après modification : « dotf install ». Un module retiré de la liste est désinstallé.
DOTF_MODULES="starship zsh-autosuggestions zsh-syntax-highlighting"

# Profils (dossier $DOTF/profiles), ex. nfs-home : home sur le réseau, caches sur le disque local.
# DOTF_PROFILES="nfs-home"

# kpsync : fichier synchronisé avec sa copie distante.
# KPSYNC_LOCAL="$HOME/notes/fichier"
# KPSYNC_REMOTE="moi@serveur.example:fichier"

# URL utilisée pour pousser les modifications du dépôt dotf depuis cette machine.
# Vide : on pousse par l'URL de clonage (HTTPS, qui demande alors un jeton, ex. via « gh auth setup-git »).
# DOTF_PUSH_URL="git@github.com:gauthier12/dotfiles.git"

# Vérification quotidienne, en arrière-plan, des mises à jour disponibles (0 pour désactiver).
# DOTF_UPDATE_CHECK=0
