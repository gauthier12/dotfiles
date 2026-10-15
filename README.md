# dotf

Mon environnement shell (bash et zsh), git et vim : installation en une commande, mise à jour, désinstallation propre,
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
| `dotf theme [dark\|light]` | thème Catppuccin sombre ou clair ; sans argument, bascule |
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
- `~/.bashrc` et `~/.zshrc` : chargent `shell/init.sh` (shells interactifs) ;
- `~/.vimrc` (ou `~/.vim/vimrc` si c'est lui qui sert), marquée `" dotf-hook` : charge `config/vim/vimrc` ;
- `~/.config/nvim/init.vim` (ou `init.lua` s'il existe), si nvim est présent : charge le même `config/vim/vimrc` ;
- `~/.ssh/config`, à la fin : `Match all`, puis `Include` de `~/.config/dotf/ssh_config` et de `config/ssh/config`.
  ssh garde la première valeur trouvée : tes hôtes passent avant la config locale, qui passe avant la commune ;
- `~/.ssh/authorized_keys` : les clés de `config/ssh/authorized_keys` (la clé passe-partout), une ligne marquée par
  clé, retirées à la désinstallation ; les autres clés ne sont jamais touchées ;
- `~/.tmux.conf` (ou `~/.config/tmux/tmux.conf` si c'est lui qui sert), si tmux est présent : `source-file -q` de
  `config/tmux/tmux.conf` puis de `~/.config/dotf/tmux.conf` ;
- `~/.Xresources`, si `xrdb` est présent : un petit bloc qui inclut `config/x/Xresources` puis
  `~/.config/dotf/Xresources`, chacun seulement s'il existe. `dotf install` les recharge dans une session graphique.

Pour git, `~/.gitconfig` reçoit une ligne `include.path` vers `config/git/config` du dépôt, qui inclut à son
tour `~/.config/dotf/gitconfig` (propre à la machine, prioritaire).

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
| URL tapée ou collée | zsh | `?`, `&`… protégés automatiquement |
| Ctrl-Z sur une ligne vide | zsh | reprend le programme suspendu (`fg`) |
| `zmv` | zsh | renommage en masse : `zmv '(*).jpeg' '$1.jpg'` |
| `# commentaire` | bash, zsh | accepté dans une commande tapée |
| Mode vi | bash, zsh | ligne de commande en mode vi : Échap → mode normal. Le curseur l'indique (barre en insertion, bloc en normal), et le prompt starship aussi en zsh. |
| ↑ ↓, et `k` `j` en mode normal | bash, zsh | historique filtré par le début de ce qui est déjà tapé |
| `v` en mode normal | bash, zsh | édite la ligne dans `$EDITOR` (bash l'exécute en sortant) |
| Ctrl-← → | bash, zsh | mot précédent ou suivant |
| Ctrl-A, Ctrl-E, Ctrl-R, Ctrl-W, Ctrl-U | zsh (bash : sauf Ctrl-W et Ctrl-U, déjà présents) | restent disponibles en insertion. Ctrl-W s'arrête aux `/ . - =`. |
| Ctrl-S | bash, zsh | ne fige plus le terminal |
| `br` | bash, zsh | broot, puis va dans le dossier choisi en le quittant (module `broot`) |
| `git ddiff`, `git dshow`, `git dlog -p` | git | diff, show et log avec difftastic (module `difftastic`) |

### vim

`config/vim/vimrc` part des réglages de base de vim (`defaults.vim`), puis :

| Élément | Effet |
|---|---|
| Thème | Catppuccin du mode choisi par `dotf theme` (module `vim-catppuccin`), sinon habamax ; barre d'état lightline (module `vim-lightline`) aux mêmes couleurs |
| `:Spellfr`, `:Spellen`, `:Spellno` | orthographe française, anglaise, ou aucune. Fautes soulignées dans le terminal. Le dictionnaire français est dans le dépôt (marche hors ligne) ; les mots ajoutés (`zg`) vont dans `~/.config/dotf/vim/spell/`. |
| F9, F10 | numéros de ligne, numéros relatifs |
| Souris | active dans vim (clic, molette, sélection) ; **Maj** + sélection ou clic milieu : copier-coller du terminal, y compris en ssh |
| `:find` | cherche aussi dans les sous-dossiers |
| Indentation | 3 espaces ; recherche insensible à la casse |
| netrw (`:Explore`) | en arbre, sans bandeau |
| Types de fichiers | Gibiane (`.dgibi`, `.gibi`, `.proc`, `.procedur` : coloration, indentation), Esope (`.eso`, `.INC` → Fortran), G-code (`.nc`, `.ngc`, `.gcode`, `.gco`) |
| gvim | police Hasklug Nerd Font Mono, sans barre d'outils |

### Thème Catppuccin, sombre ou clair

`dotf theme` bascule entre **mocha** (sombre, par défaut) et **latte** (clair) ; `dotf theme dark|light` force l'un ou
l'autre. Le choix est propre à la machine (`~/.local/state/dotf/theme`).

- Le shell envoie la palette au terminal, quel qu'il soit (urxvt, xterm, Windows Terminal, volet tmux, y compris en
  ssh), à chaque prompt : une bascule s'applique au prompt suivant, et le terminal retrouve ses couleurs en sortant
  d'une session ssh. ls, difft, dust, starship… suivent.
- Tout de suite : les vim ouverts (signal USR1) et la coloration de la ligne zsh. broot et gitui : au prochain lancement.
- ssh transmet le mode du poste (`LC_DOTF_THEME`, par `SendEnv` dans `config/ssh/config`) : la session distante le
  suit, et `dotf theme` y prévient qu'il n'a pas d'effet. Le serveur doit accepter `LC_*` (`AcceptEnv`, le défaut
  sous Debian).

### ssh

`config/ssh/config`, pour tous les hôtes : envoi du thème, connexion maintenue (`ServerAliveInterval 60`), réutilisation
de la première connexion vers un hôte pendant 10 minutes (`ControlMaster`, sockets `~/.ssh/cm-*`), clés ajoutées à
l'agent. Pour ne pas réutiliser une connexion : `ssh -o ControlMaster=no …`.

### Terminal et polices

- `config/x/Xresources` : urxvt (Hasklug Nerd Font Mono 11), et xterm en repli.
- Le prompt starship et la barre lightline utilisent des icônes Nerd Font : le terminal doit afficher une police
  Nerd Font (module `nerd-fonts` sur un poste Linux ; pour Windows Terminal, l'installer côté Windows).

## Personnaliser une machine

`~/.config/dotf/` est créé depuis `local.example/` au premier `dotf install`, puis n'est plus jamais modifié
ni supprimé par dotf.

- `config.sh` : `DOTF_MODULES`, `DOTF_PROFILES` et autres réglages ;
- `gitconfig` : config git de la machine (adresse, identité par dossier, certificats, identifiants…) ;
- `env.d/*.sh` : variables d'environnement (proxy, PATH supplémentaires…) ;
- `rc.d/*.sh|bash|zsh` : alias, fonctions, réglages interactifs ;
- `bin/` : scripts propres à la machine, ajoutés au PATH ;
- `Xresources`, `tmux.conf` : ressources X et réglages tmux de la machine, prioritaires ;
- `vimrc` : réglages vim, chargés en dernier ; `vim/` : runtime vim de la machine (syntaxes, dictionnaires…), prioritaire sur celui du dépôt.

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
| `rustup` | Rust (rustup, cargo, rustc), aux emplacements standard `~/.rustup` et `~/.cargo`. Requis par les modules installés avec cargo. Le retirer désinstalle Rust, y compris ce qui a été installé à la main avec cargo. |
| `zsh-syntax-highlighting` | colore la commande pendant la frappe (rouge si elle n'existe pas) |
| `broot` | navigation dans l'arborescence, et `br` pour y changer de dossier |
| `difftastic` | `difft`, diff qui comprend la syntaxe |
| `dust` | `du` lisible (installé par son script officiel) |
| `gitui` | interface git en terminal |
| `lowfi` | musique lo-fi, compilé avec cargo (`rustup` installé avant). Demande `pkg-config` et les en-têtes ALSA et OpenSSL (Debian : `pkg-config libasound2-dev libssl-dev`). |
| `catppuccin` | thèmes Catppuccin : palette du terminal, zsh-syntax-highlighting, broot, gitui |
| `vim-catppuccin`, `vim-lightline` | thème et barre d'état de vim |
| `nerd-fonts` | polices Nerd Font, variante Mono, listées dans `DOTF_FONTS` (par défaut Hasklig et FiraCode), dans `~/.local/share/fonts/nerd-fonts`. Changer la liste : `dotf update`. |

Chaque outil est installé par la méthode recommandée par son projet. Les complétions bash et zsh qu'un module
fournit sont chargées automatiquement.

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
- `pkg_remove` : à faire en plus à la désinstallation, pour ce qui est installé hors de son dossier ;
- un fichier `.env.sh` écrit par `pkg_install` dans son dossier : chargé par les shells et avant chaque installation (ex. PATH) ;
- des fichiers `.rc.bash` et `.rc.zsh` dans son dossier : chargés par les shells interactifs (ex. la fonction `br`) ;
- des complétions dans `completions/bash/<commande>` et `completions/zsh/_<commande>` (voir `add_completion`).

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
| `git_head <url>` | commit de la branche principale, pour un dépôt sans tags |
| `add_completion <bash\|zsh> <commande>` | enregistre l'entrée standard comme complétion de la commande |
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
