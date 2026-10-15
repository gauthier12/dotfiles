# Configuration propre à cette machine (hors git).
# Chargée par les shells (via shell/env.sh) et par la commande dotf.

# Modules : ceux du socle ($DOTF/modules/default) sont installés partout. Ici, l'écart de cette machine :
# « nom » ajoute un module, « -nom » en retire un du socle. Ex. : DOTF_MODULES="joplin -nerd-fonts"
#   joplin    application de notes Joplin (bureau, AppImage x86_64)
#   lapce     éditeur graphique Lapce, avec les thèmes Catppuccin
#   lowfi     compilé avec cargo (rustup installé avant) ; demande pkg-config et les en-têtes ALSA/OpenSSL
#   rustup    Rust (rustup, cargo) ; inutile de l'ajouter pour lowfi
# Liste et rôle de chaque module : README, section Modules. Après modification : « dotf install ».
DOTF_MODULES=""

# Polices du module nerd-fonts (noms des archives sur github.com/ryanoasis/nerd-fonts/releases).
# DOTF_FONTS="Hasklig FiraCode"

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
