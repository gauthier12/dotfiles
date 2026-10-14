# shellcheck shell=sh disable=SC2034
# Modèle : copier en modules/<nom>.sh, puis ajouter <nom> à DOTF_MODULES.
# pkg_install travaille dans un dossier vide qui deviendra ~/.local/opt/<nom>.

# Exécutables à lier dans ~/.local/bin, relatifs au dossier (vide si aucun).
pkg_bins="outil"

# Facultatif : modules requis (installés avant celui-ci).
# pkg_needs="rustup"

# Dernière version. Choisir une ligne :
pkg_latest() { gh_latest auteur/outil; }                      # release GitHub
# pkg_latest() { git_latest https://github.com/auteur/outil; } # tag git
# pkg_latest() { crate_latest outil; }                         # crate (avec pkg_needs="rustup")

# Installe la version $1 dans le dossier courant. Choisir un bloc :
pkg_install() {
  # Release GitHub, archive vérifiée par sa somme :
  _f="outil-$1-$(uname -m)-linux.tar.gz"
  gh_get auteur/outil "v$1" "$_f" "$_f.sha256" &&
    tar -xzf "$_f" outil && rm "$_f"

  # Dépôt git (avec git_latest) :
  # git clone -q --depth 1 --branch "$1" https://github.com/auteur/outil .

  # Crate (avec crate_latest ; pkg_bins="bin/outil") :
  # cargo install -q --locked --root "$PWD" outil --version "$1"
}

# Facultatif : mise à jour sur place, dans le dossier du module (sinon : réinstallation).
# pkg_update() { outil self-update; }

# Facultatif : à faire en plus à la désinstallation (installation hors du dossier du module).
# pkg_remove() { rm -rf "$HOME/.outil"; }
