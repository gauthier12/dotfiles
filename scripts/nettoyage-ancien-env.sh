#!/bin/sh
# Remet à zéro l'ancien environnement (~/.local/dotfiles) avant l'installation de dotf.
# Tout ce qui est retiré est déplacé dans ~/ancien-env-<date>/, en gardant les chemins : on peut y faire des diff.
set -eu
cd "$HOME"

old="
.profile .bashrc .bash_profile .zshrc .zshenv .vimrc .gitconfig .Xresources
.config/libzsh .config/amp .config/broot .config/gitui .config/nvim
bin/HABupdate .fonts .local/dotfiles
"

# Ce qui existe parmi la liste
present=
for f in $old; do
  if [ -e "$f" ] || [ -L "$f" ]; then present="$present $f"; fi
done
[ -n "$present" ] || { echo "Rien à nettoyer."; exit 0; }

backup="$HOME/ancien-env-$(date +%F-%H%M%S)"
echo "Sera déplacé dans ~/${backup##*/}/ :"
for f in $present; do echo "  ~/$f"; done
echo "Puis : .bashrc et .profile de /etc/skel, cargo uninstall broot difftastic du-dust."
printf "Continuer ? [o/N] "
read -r rep
[ "$rep" = o ] || [ "$rep" = O ] || { echo "Annulé."; exit 1; }

# Déplacement dans la sauvegarde
for f in $present; do
  mkdir -p "$backup/$(dirname "$f")"
  mv "$f" "$backup/$f"
done
rmdir bin 2>/dev/null || true

# Fichiers rc de la distribution
for f in .bashrc .profile; do
  if [ -r "/etc/skel/$f" ]; then cp "/etc/skel/$f" "$f"; fi
done

# Polices
if command -v fc-cache >/dev/null 2>&1; then fc-cache -f; fi

# Outils installés avec cargo, remplacés par les modules
if [ -x "$HOME/.cargo/bin/cargo" ]; then
  for c in broot difftastic du-dust; do
    "$HOME/.cargo/bin/cargo" uninstall -q "$c" 2>/dev/null || true
  done
fi

cat <<EOF

Nettoyage terminé. Sauvegarde : $backup
  ex. : diff $backup/.bashrc ~/.bashrc

À faire à la main :
  - ~/.git-credentials : révoquer le jeton sur GitHub, puis supprimer le fichier ;
  - Rust : « rustup self uninstall » si inutile, sinon ajouter « rustup » à DOTF_MODULES ;
  - installer dotf :
      sh -c "\$(curl -fsSL https://raw.githubusercontent.com/gauthier12/dotfiles/main/install.sh)"
      dotf edit                          (DOTF_MODULES ; DOTF_PROFILES="nfs-home" si le home est sur le réseau)
      \$EDITOR ~/.config/dotf/gitconfig   (identité git)
  - quand tout marche : rm -rf $backup
EOF
