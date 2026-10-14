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

## Où sont les choses

| Chemin | Contenu | Dans git |
|---|---|---|
| `~/.local/share/dotf` | ce dépôt | oui |
| `~/.config/dotf` | config propre à la machine | **non** |
| `~/.local/state/dotf` | sauvegardes, liste des liens et modules posés | non |
| `~/.local/bin` | binaires installés par les modules | non |

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

## Personnaliser une machine

`~/.config/dotf/` est créé depuis `local.example/` au premier `dotf install`, puis n'est plus jamais modifié
ni supprimé par dotf.

- `config.sh` : `DOTF_MODULES="starship …"` et autres réglages ;
- `env.d/*.sh` : variables d'environnement (proxy, PATH supplémentaires…) ;
- `rc.d/*.sh|bash|zsh` : alias, fonctions, réglages interactifs ;
- `bin/` : scripts propres à la machine, ajoutés au PATH.

## Modules

Un module est un fichier `modules/<nom>.sh` qui définit `mod_installed`, `mod_install`, `mod_update` et
`mod_remove`. On l'active en ajoutant son nom à `DOTF_MODULES`. Si on l'en retire, le prochain `dotf install`
le désinstalle.

| Module | Rôle |
|---|---|
| `starship` | prompt commun à bash et zsh, configuré dans `config/starship.toml`. Sans lui, ou avec `TERM=dumb`, un prompt simple prend le relais. |
| `gitleaks` | détection de secrets utilisée par le garde-fou. Binaire officiel vérifié par SHA-256, mis à jour par `dotf update`. |

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

- **des secrets reconnaissables à leur forme** (règles dans `lib/scan.sh`) : clés privées, clés publiques SSH,
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
