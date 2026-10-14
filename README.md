# dotf

Mon environnement shell (bash et zsh) : installation en une commande, mise à jour, désinstallation propre,
et personnalisation par machine hors git.

## Installation

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/gauthier12/dotfiles/main/install.sh)"
```

ou, depuis un clone :

```sh
git clone https://github.com/gauthier12/dotfiles ~/.local/share/dotf
~/.local/share/dotf/install.sh
```

Seul git est requis. curl ou wget servent aux modules optionnels.

## Commandes

| Commande | Effet |
|---|---|
| `dotf install` | branche les shells, pose les liens, installe les modules. Peut être relancé à volonté. |
| `dotf update` | `git pull --ff-only`, puis `install`, puis mise à jour des modules actifs |
| `dotf status` | état des branchements, liens, modules, retard ou avance sur le dépôt distant |
| `dotf edit` | ouvre la config locale de la machine |
| `dotf uninstall` | débranche tout, retire liens et modules, restaure les fichiers sauvegardés |
| `dotf uninstall --purge` | idem, puis supprime le dépôt et l'état (refusé s'il reste du travail non commité ou non poussé) |

## Modifier et propager à ses autres machines

`~/.local/share/dotf` est un clone git ordinaire :

```sh
cd ~/.local/share/dotf
git commit -am "…" && git push   # sur la machine où l'on a modifié
dotf update                      # sur chacune des autres
```

- **Pousser** : le clone fait par `curl | sh` est en HTTPS. Deux possibilités :
  - régler `DOTF_PUSH_URL="git@github.com:gauthier12/dotfiles.git"` dans `~/.config/dotf/config.sh`, puis lancer
    `dotf install`, pour pousser en SSH ;
  - ou garder HTTPS et s'authentifier avec `gh auth login` puis `gh auth setup-git`.
- **Être prévenu** : une fois par jour au plus, un shell interactif lance un `git fetch` en arrière-plan. Les shells
  suivants affichent `dotf : N mise(s) à jour disponible(s)`. La mise à jour reste toujours manuelle.
  Pour la désactiver : `DOTF_UPDATE_CHECK=0` dans la config locale.

## Où sont les choses

| Chemin | Contenu | Dans git |
|---|---|---|
| `~/.local/share/dotf` | ce dépôt | oui |
| `~/.config/dotf` | config propre à la machine | **non** |
| `~/.local/state/dotf` | sauvegardes, liste des liens et modules posés | non |
| `~/.local/opt` | logiciels installés par les modules | non |
| `~/.local/bin` | liens vers leurs exécutables | non |

## Comment c'est branché

`dotf install` ajoute **une ligne** marquée `# dotf-hook` à la fin des fichiers suivants :

- `~/.profile`, `~/.zshenv` et `~/.bash_profile` s'il existe : chargent `shell/env.sh` (PATH, variables) ;
- `~/.bashrc` et `~/.zshrc` : chargent `shell/init.sh` (shells interactifs).

**Pour débrancher à la main, il suffit de supprimer ces lignes.** Si le dépôt disparaît, elles ne font rien et
les shells démarrent normalement.

Ordre de chargement d'un shell interactif :

1. `shell/env.sh`, qui charge ensuite `~/.config/dotf/config.sh` puis `~/.config/dotf/env.d/*.sh` ;
2. `shell/rc.d/*` du dépôt ;
3. `~/.config/dotf/rc.d/*`, qui peut donc surcharger le dépôt.

Dans les dossiers `rc.d`, l'ordre est alphabétique (on préfixe par un numéro). Les `*.sh` sont chargés par bash **et**
zsh ; les `*.bash` et `*.zsh` seulement par le shell concerné.

## Ce que fournit l'environnement

| Commande | Shells | Effet |
|---|---|---|
| `ls` | bash, zsh | en couleur (si le `ls` du système le permet) |
| Prompt | bash, zsh | heure, user@hôte (une couleur propre à chaque machine, tirée de son nom), dossier, git ; `❯` rouge si la commande a échoué |
| Titre du terminal | bash, zsh | hôte et dossier ; en zsh, la commande pendant qu'elle tourne |
| `setTitle <texte>` | bash, zsh | fixe le titre ; sans argument, revient au titre automatique |
| `kpsync` | bash, zsh | synchronise un fichier avec sa copie distante, la version la plus récente gagne (l'ancienne est gardée en `fichier~`). Réglages `KPSYNC_LOCAL` et `KPSYNC_REMOTE` dans la config locale. |
| `-` | bash, zsh | retour au dossier précédent (`cd -`) |
| `d` | zsh | les 10 derniers dossiers visités, numérotés (chaque `cd` les empile) |
| `1` … `9` | zsh | retour au dossier n° 1 … 9 de cette liste |
| `history` | bash, zsh | historique daté (zsh : en entier). 50 000 lignes en mémoire, 10 000 sur disque, partagé entre les terminaux ouverts. Une commande précédée d'une espace n'est pas enregistrée. |
| Tab | zsh | menu navigable, insensible à la casse, mots partiels (`f-b` → `foo-bar`) |
| Tab sur `kill` | zsh | menu de ses propres processus |
| Mode vi | bash, zsh | ligne de commande en mode vi : Échap → mode normal. Le curseur l'indique (barre en insertion, bloc en normal), et le prompt starship aussi en zsh. |
| ↑ ↓, et `k` `j` en mode normal | bash, zsh | historique filtré par le début de ce qui est déjà tapé |
| `v` en mode normal | bash, zsh | édite la ligne dans `$EDITOR` (bash l'exécute en sortant) |
| Ctrl-← → | bash, zsh | mot précédent ou suivant |
| Ctrl-A, Ctrl-E, Ctrl-R, Ctrl-W, Ctrl-U | zsh (bash : sauf Ctrl-W et Ctrl-U, déjà présents) | restent disponibles en insertion. Ctrl-W s'arrête aux `/ . - =`. |
| Ctrl-S | bash, zsh | ne fige plus le terminal |

## Personnaliser une machine

`~/.config/dotf/` est créé depuis `local.example/` au premier `dotf install`, puis n'est plus jamais modifié
ni supprimé par dotf.

- `config.sh` : `DOTF_MODULES`, `DOTF_PROFILES` et autres réglages ;
- `env.d/*.sh` : variables d'environnement (proxy, PATH supplémentaires…) ;
- `rc.d/*.sh|bash|zsh` : alias, fonctions, réglages interactifs ;
- `bin/` : scripts propres à la machine, ajoutés au PATH.

## Profils

Un profil regroupe des réglages propres à un type de machine ou de réseau : `profiles/<nom>.sh`, chargé par tous
les shells quand `<nom>` figure dans `DOTF_PROFILES` (config locale).

| Profil | Rôle |
|---|---|
| `nfs-home` | home sur le réseau : les caches (`XDG_CACHE_HOME`) vont sur le disque local |

## Modules

Un module est un logiciel installé en espace utilisateur, sans root. On l'active en ajoutant son nom à
`DOTF_MODULES`. `dotf install` l'installe, `dotf update` le met à jour, et si on le retire de la liste,
le prochain `dotf install` le désinstalle.

| Module | Rôle |
|---|---|
| `starship` | prompt commun à bash et zsh (`config/starship.toml`). Sans lui, ou avec `TERM=dumb`, un prompt simple prend le relais. |
| `gitleaks` | détection de secrets pour le garde-fou |
| `joplin` | Joplin, version bureau (AppImage). Les notes ne sont jamais touchées. |
| `zsh-autosuggestions` | suggestion grisée tirée de l'historique pendant la frappe ; → ou Fin l'accepte |
| `rustup` | Rust (rustup, cargo, rustc) dans `~/.local/opt/rustup`. Requis par les modules installés avec cargo. |
| `zsh-syntax-highlighting` | colore la commande pendant la frappe (rouge si elle n'existe pas) |

### Écrire un module

Partir du modèle `modules/_template.sh`, copié en `modules/<nom>.sh`. Un module définit trois choses :

```sh
pkg_bins=gitleaks                         # exécutables à lier dans ~/.local/bin

pkg_latest() { gh_latest gitleaks/gitleaks; }   # dernière version

pkg_install() {                           # installe la version $1 dans le dossier courant
  _f="gitleaks_$1_linux_x64.tar.gz"
  gh_get gitleaks/gitleaks "v$1" "$_f" "gitleaks_$1_checksums.txt" &&
    tar -xzf "$_f" gitleaks && rm "$_f"
}
```

Facultatif :
- `pkg_needs="rustup"` : modules requis, installés avant (sans avoir à les mettre dans `DOTF_MODULES`) ;
- `pkg_update` : mise à jour sur place, au lieu de réinstaller (ex. `rustup update`) ;
- un fichier `.env.sh` écrit par `pkg_install` dans son dossier : chargé par les shells (ex. `CARGO_HOME`).

dotf fait le reste :
- installe dans `~/.local/opt/<nom>`, en remplaçant d'un coup l'ancienne version une fois la nouvelle prête ;
- enregistre la version ;
- pose les liens, sans jamais écraser un fichier qui n'est pas à lui ;
- met à jour quand la version change, et désinstalle.

Outils disponibles :

| Outil | Rôle |
|---|---|
| `gh_latest <dépôt>` | dernière release GitHub, sans le « v » |
| `gh_get <dépôt> <tag> <fichier> [<sommes>]` | télécharge une pièce de release et vérifie sa somme SHA-256 ou SHA-512 |
| `download <url> [<url des sommes>]` | télécharge dans le dossier courant et vérifie la somme |
| `crate_latest <crate>` | dernière version stable sur crates.io |
| `git_latest <url>` | dernier tag de version d'un dépôt git, tel quel |
| `fetch <url>` | télécharge sur la sortie standard |

## Liens symboliques

Le fichier `links` déclare des liens `source-dans-le-dépôt  cible` (par ex. `config/helix/config.toml  ~/.config/helix/config.toml`).
Si une cible existe déjà, elle est sauvegardée dans `~/.local/state/dotf/backup/`, puis restaurée à la
désinstallation. Une ligne retirée de `links` fait retirer le lien au prochain `install` ou `update`.

## Garde-fou anti-fuite

Ce dépôt est public : rien de ce qui identifie une machine, une personne ou un employeur ne doit y entrer.
`dotf install` active deux hooks git sur le clone (`core.hooksPath = .githooks`) :

- **pre-commit** : vérifie les lignes ajoutées au commit ;
- **pre-push** : vérifie tous les commits sur le point d'être poussés. Il rattrape un `git commit --no-verify`,
  ou un commit fait sur une machine sans liste noire.

Ils cherchent :

- **des secrets reconnaissables à leur forme** (règles dans `lib/guard.sh`) : clés privées, clés publiques SSH,
  jetons GitHub/GitLab/AWS/Slack, mots de passe ou jetons affectés en clair, longues chaînes hexadécimales ;
- **ta liste noire** `~/.config/dotf/denylist`, jamais versionnée puisque la publier reviendrait à publier ce
  qu'elle protège. Un motif ERE par ligne, insensible à la casse, mot entier :
  ```
  mon-domaine\.fr
  serveur[0-9]+
  ```
- en plus, avec **gitleaks** (module `gitleaks`, ou toute version ≥ 8.19 dans le PATH), ses quelques centaines de formats de jetons.

Une ligne signalée à tort passe si elle contient le commentaire `dotf-allow`. `dotf scan --all` vérifie tout le
dépôt. Côté GitHub, activer aussi *Secret scanning* et *Push protection* (Settings → Code security).

Si une fuite passe malgré tout, il ne suffit pas de réécrire l'historique : il faut **révoquer et régénérer**
le secret.

## Tests

```sh
tests/run.sh                       # hors ligne, dans un HOME jetable
DOTF_TEST_NETWORK=1 tests/run.sh   # installe vraiment starship
```

Ils couvrent le bootstrap, l'idempotence, bash et zsh (interactifs, de connexion, non interactifs), la mise à jour,
les liens, la restauration octet pour octet des fichiers rc, la purge et le garde-fou. Ils lancent aussi shellcheck s'il est présent.
