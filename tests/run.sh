#!/usr/bin/env bash
# Les commandes passées aux shells testés sont volontairement entre apostrophes,
# et les tests sont écrits en « cond && ok || ko ».
# shellcheck disable=SC2015,SC2016,SC2088
#
# Tests de bout en bout de dotf, dans un HOME jetable.
#   tests/run.sh                  hors ligne : l'installation des modules est simulée en échec
#   DOTF_TEST_NETWORK=1 tests/run.sh   installe vraiment starship
# Le dépôt testé est une copie de l'arbre de travail courant, modifications non commitées comprises.
set -u

SRC=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/dotf-test.XXXXXX")
trap 'rm -rf "$T"' EXIT

pass=0 fail=0
ok() { pass=$((pass + 1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
ko() { fail=$((fail + 1)); printf '  \033[31m✗ %s\033[0m\n' "$1"; [ -n "${2-}" ] && printf '%s\n' "$2" | sed 's/^/      /'; }
check() { # check "description" commande...
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else ko "$d"; fi
}
section() { printf '\n\033[1m%s\033[0m\n' "$*"; }

SHELLCHECK=$(command -v shellcheck || true)

# --- Environnement isolé -----------------------------------------------------
export HOME="$T/home"
unset XDG_CONFIG_HOME XDG_STATE_HOME XDG_DATA_HOME ZDOTDIR DOTF DOTF_LOCAL DOTF_STATE STARSHIP_CONFIG
mkdir -p "$HOME"
BASE_PATH=/usr/local/bin:/usr/bin:/bin
if [ -z "${DOTF_TEST_NETWORK-}" ]; then
  # curl et wget factices : aucun accès réseau, l'installation des modules échoue proprement.
  mkdir -p "$T/fakebin"
  printf '#!/bin/sh\nexit 1\n' >"$T/fakebin/curl"
  cp "$T/fakebin/curl" "$T/fakebin/wget"
  chmod +x "$T/fakebin/"*
  BASE_PATH="$T/fakebin:$BASE_PATH"
fi
export PATH="$BASE_PATH"
DOTF_DIR="$HOME/.local/share/dotf"
LOCAL="$HOME/.config/dotf"
STATE="$HOME/.local/state/dotf"

# Lance un shell propre ; stderr filtré du bruit des shells interactifs sans terminal.
run_shell() { # run_shell <bash|zsh> <options> <commande>
  env -i HOME="$HOME" PATH="$BASE_PATH" TERM="${RUN_TERM:-xterm-256color}" "$1" "$2" "$3" 2>"$T/stderr"
  local rc=$?
  grep -v -e 'cannot set terminal process group' -e 'no job control' "$T/stderr" >"$T/stderr.f" || true
  return $rc
}
stderr_clean() { [ ! -s "$T/stderr.f" ]; }

# --- Dépôt « distant » : copie de l'arbre de travail ---------------------------
REMOTE="$T/remote"
mkdir -p "$REMOTE"
(cd "$SRC" && tar --exclude=.git -cf - .) | tar -C "$REMOTE" -xf -
git -C "$REMOTE" init -q -b main
git -C "$REMOTE" -c user.name=t -c user.email=t@t add -A
git -C "$REMOTE" -c user.name=t -c user.email=t@t commit -qm init
commit_remote() { git -C "$REMOTE" -c user.name=t -c user.email=t@t add -A && git -C "$REMOTE" -c user.name=t -c user.email=t@t commit -qm "$1"; }

# --- Fichiers rc d'origine ---------------------------------------------------
printf '# bashrc d origine\nexport ORIG_BASHRC=1\n' >"$HOME/.bashrc"
printf '# zshrc d origine\nexport ORIG_ZSHRC=1\n' >"$HOME/.zshrc"
printf '# profile d origine\n' >"$HOME/.profile"
mkdir -p "$T/orig"
cp "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$T/orig/"

# =============================================================================
section "1. Bootstrap (équivalent de curl | sh)"
out=$(cd "$T" && DOTF_REPO="$REMOTE" sh -c "$(cat "$REMOTE/install.sh")" 2>&1)
check "dépôt cloné dans ~/.local/share/dotf" test -d "$DOTF_DIR/.git"
check "config locale créée depuis local.example" test -f "$LOCAL/config.sh"
for f in .profile .bashrc .zshenv .zshrc; do
  check "$f branché" grep -q '# dotf-hook' "$HOME/$f"
done
if [ -z "${DOTF_TEST_NETWORK-}" ]; then
  if printf '%s' "$out" | grep -q 'module starship : échec'; then ok "hors ligne : échec du module signalé sans interrompre l'installation"; else ko "échec du module signalé" "$out"; fi
  # Pour la suite : pas de module.
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
fi

section "2. Idempotence"
mkdir -p "$T/after1"
cp "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshenv" "$HOME/.zshrc" "$T/after1/"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
for f in .profile .bashrc .zshenv .zshrc; do
  check "$f inchangé après une 2e installation" cmp -s "$HOME/$f" "$T/after1/$f"
done

section "3. Shells interactifs"
mkdir -p "$LOCAL/rc.d"
echo 'T_COMMON=ok' >"$LOCAL/rc.d/10-test.sh"
echo 'T_BASH=ok' >"$LOCAL/rc.d/20-test.bash"
echo 'T_ZSH=ok' >"$LOCAL/rc.d/20-test.zsh"
mkdir -p "$LOCAL/env.d"
echo 'export T_ENV=ok' >"$LOCAL/env.d/test.sh"

probe='echo "dotf=$(command -v dotf) common=${T_COMMON-} bash=${T_BASH-} zsh=${T_ZSH-} env=${T_ENV-} orig=${ORIG_BASHRC-}${ORIG_ZSHRC-}"'
r=$(run_shell bash -ic "$probe")
[ "$r" = "dotf=$DOTF_DIR/bin/dotf common=ok bash=ok zsh= env=ok orig=1" ] && ok "bash -i : dotf, fragments .sh/.bash, env.d, rc d'origine" || ko "bash -i" "$r"
stderr_clean && ok "bash -i : aucune erreur" || ko "bash -i : erreurs" "$(cat "$T/stderr.f")"
r=$(run_shell zsh -ic "$probe")
[ "$r" = "dotf=$DOTF_DIR/bin/dotf common=ok bash= zsh=ok env=ok orig=1" ] && ok "zsh -i : dotf, fragments .sh/.zsh, env.d, rc d'origine" || ko "zsh -i" "$r"
stderr_clean && ok "zsh -i : aucune erreur" || ko "zsh -i : erreurs" "$(cat "$T/stderr.f")"

dups='printf "%s\n" "$PATH" | tr : "\n" | sort | uniq -d'
r=$(run_shell bash -ic "bash -ic '$dups' 2>/dev/null")
[ -z "$r" ] && ok "bash imbriqué : PATH sans doublon" || ko "bash : doublons dans PATH" "$r"
r=$(run_shell zsh -ic "zsh -ic '$dups'")
[ -z "$r" ] && ok "zsh imbriqué : PATH sans doublon" || ko "zsh : doublons dans PATH" "$r"

# Rien ne doit se charger dans un shell non interactif (scp, ssh host cmd...).
r=$(env -i HOME="$HOME" PATH="$BASE_PATH" zsh -c 'echo "${T_COMMON-}"')
[ -z "$r" ] && ok "zsh non interactif : rc.d non chargé" || ko "zsh non interactif charge rc.d"

section "4. Shells de connexion"
r=$(run_shell bash -lc 'command -v dotf; echo "${T_ENV-}"' | tr '\n' ' ')
[ "$r" = "$DOTF_DIR/bin/dotf ok " ] && ok "bash -l : env.sh chargé via ~/.profile" || ko "bash -l" "$r"
r=$(run_shell zsh -lc 'command -v dotf; echo "${T_ENV-}"' | tr '\n' ' ')
[ "$r" = "$DOTF_DIR/bin/dotf ok " ] && ok "zsh -l : env.sh chargé via ~/.zshenv" || ko "zsh -l" "$r"
printf '# bash_profile\n' >"$HOME/.bash_profile"
cp "$HOME/.bash_profile" "$T/orig/"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
check "~/.bash_profile existant : branché lui aussi" grep -q '# dotf-hook' "$HOME/.bash_profile"

section "5. Prompt"
if [ -z "${DOTF_TEST_NETWORK-}" ]; then
  r=$(run_shell bash -ic 'echo "$PROMPT_COMMAND"')
  [ "$r" = "_dotf_prompt;_dotf_history_sync" ] && ok "bash : prompt de repli sans starship" || ko "bash : prompt de repli" "$r"
  r=$(run_shell zsh -ic 'echo "$PROMPT"')
  case $r in *'%n@%m'*) ok "zsh : prompt de repli sans starship" ;; *) ko "zsh : prompt de repli" "$r" ;; esac
else
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="starship"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "starship installé dans ~/.local/bin" test -x "$HOME/.local/bin/starship"
  r=$(run_shell bash -ic 'echo "$PROMPT_COMMAND"')
  case $r in *starship*) ok "bash : prompt starship" ;; *) ko "bash : prompt starship" "$r" ;; esac
  r=$(run_shell bash -ic 'echo "$STARSHIP_PROMPT_COMMAND"')
  [ "$r" = "_dotf_history_sync" ] && ok "bash : starship conserve la synchro de l'historique" || ko "bash : STARSHIP_PROMPT_COMMAND" "$r"
  r=$(run_shell zsh -ic 'echo "$STARSHIP_CONFIG"')
  [ "$r" = "$DOTF_DIR/config/starship.toml" ] && ok "zsh : STARSHIP_CONFIG pointe vers le dépôt" || ko "zsh : STARSHIP_CONFIG" "$r"
  r=$(RUN_TERM=dumb run_shell bash -ic 'echo "$PROMPT_COMMAND"')
  [ "$r" = "_dotf_prompt;_dotf_history_sync" ] && stderr_clean && ok "TERM=dumb : prompt de repli malgré starship" || ko "TERM=dumb" "$r $(cat "$T/stderr.f")"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="gitleaks"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "module retiré de DOTF_MODULES : starship désinstallé" test ! -e "$HOME/.local/bin/starship"
  check "gitleaks installé dans ~/.local/bin" "$HOME/.local/bin/gitleaks" version
  out=$("$DOTF_DIR/bin/dotf" status 2>&1)
  case $out in *"gitleaks utilisé en complément"*) ok "status : gitleaks détecté hors PATH" ;; *) ko "status : gitleaks" "$out" ;; esac
  out=$("$DOTF_DIR/bin/dotf" update 2>&1)
  case $out in *"module gitleaks : à jour"*) ok "update : module gitleaks mis à jour" ;; *) ko "update gitleaks" "$out" ;; esac
  # Clé Stripe factice : inconnue des règles intégrées, reconnue par gitleaks.
  printf 'stripe = "sk_%s_%s"\n' live 4eC39HqLyjWDarjtT1zdp7dc >"$DOTF_DIR/fuite.txt"
  git -C "$DOTF_DIR" add fuite.txt
  if git -C "$DOTF_DIR" -c user.name=t -c user.email=t@t commit -qm t >/dev/null 2>&1; then ko "hook : gitleaks bloque une clé Stripe"; else ok "hook : gitleaks bloque une clé Stripe"; fi
  git -C "$DOTF_DIR" reset -q fuite.txt; rm -f "$DOTF_DIR/fuite.txt"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "gitleaks désinstallé quand retiré de DOTF_MODULES" test ! -e "$HOME/.local/bin/gitleaks"
fi

section "5b. Alias et fonctions"
probe='alias ls; alias -- -; setTitle "t i" | od -An -c | tr -s " " | tr -d "\n"'
r=$(run_shell bash -ic "$probe")
[ "$r" = "alias ls='ls --color=auto'
alias -- -='cd -'
 033 ] 0 ; t i \\a" ] && stderr_clean && ok "bash : ls en couleur, « - », setTitle" || ko "bash : alias" "$r $(cat "$T/stderr.f")"
r=$(run_shell zsh -ic 'alias ls; alias 2; [[ -o autopushd && -o pushdminus ]] && echo pushd; cd /; cd /tmp; d | wc -l | tr -d " "')
[ "$r" = "ls='ls --color=auto'
2='cd -2'
pushd
3" ] && stderr_clean && ok "zsh : ls en couleur, pile des dossiers (1-9, d)" || ko "zsh : alias" "$r $(cat "$T/stderr.f")"
r=$(run_shell zsh -ic 'setTitle "t i" | od -An -c | tr -s " " | tr -d "\n"')
[ "$r" = " 033 ] 0 ; t i \\a" ] && ok "zsh : setTitle" || ko "zsh : setTitle" "$r"

section "5c. Complétion, historique, édition de ligne"
r=$(run_shell zsh -ic 'print $+functions[compdef] $options[sharehistory] $options[histignorespace] $SAVEHIST; print -r -- $WORDCHARS; whence -w history')
[ "$r" = '1 on on 10000
*?_[]~&;!#$%^(){}<>
history: function' ] && stderr_clean && ok "zsh : compinit, historique partagé, WORDCHARS, history" || ko "zsh : complétion/historique" "$r $(cat "$T/stderr.f")"
check "zsh : dump de complétion dans ~/.cache/zsh" test -f "$HOME/.cache/zsh/zcompdump-$(zsh -c 'echo $ZSH_VERSION')"
check "zsh : compinit global de Debian évité (pas de ~/.zcompdump)" test ! -e "$HOME/.zcompdump"
r=$(run_shell bash -ic 'echo "$HISTSIZE $HISTFILESIZE $HISTCONTROL"; shopt -q histappend && shopt -q histverify && echo shopt')
[ "$r" = "50000 10000 ignoreboth
shopt" ] && stderr_clean && ok "bash : historique (taille, ignoreboth, histappend)" || ko "bash : historique" "$r $(cat "$T/stderr.f")"
printf 'echo autre-terminal\n' >>"$HOME/.bash_history"
r=$(run_shell bash -ic '_dotf_history_sync; history | grep -c autre-terminal')
[ "$r" = 1 ] && ok "bash : lit les commandes des autres terminaux" || ko "bash : synchro historique" "$r"

# Module joplin : ne remplace jamais un ~/.local/bin/joplin qui n'est pas le sien.
mkdir -p "$HOME/.local/bin"
echo autre >"$HOME/.local/bin/joplin"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="joplin"/' "$LOCAL/config.sh"
out=$("$DOTF_DIR/bin/dotf" install 2>&1)
case $out in *"joplin : $HOME/.local/bin/joplin existe déjà"*) ok "joplin : refuse d'écraser un autre joplin" ;; *) ko "joplin : écrasement" "$out" ;; esac
check "joplin : fichier existant intact" grep -qx autre "$HOME/.local/bin/joplin"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
check "joplin : fichier existant intact après retrait du module" grep -qx autre "$HOME/.local/bin/joplin"
rm -f "$HOME/.local/bin/joplin"

section "6. Mise à jour et liens"
mkdir -p "$REMOTE/config/test" "$HOME/.config"
echo "version dépôt A" >"$REMOTE/config/test/a.conf"
echo "version dépôt B" >"$REMOTE/config/test/b.conf"
printf 'config/test/a.conf  ~/.config/a.conf\nconfig/test/b.conf  ~/.config/sub/b.conf\n' >>"$REMOTE/links"
commit_remote "liens de test"
echo "a d'origine" >"$HOME/.config/a.conf"

echo "sale" >>"$DOTF_DIR/links"
if "$DOTF_DIR/bin/dotf" update >/dev/null 2>&1; then ko "update refusé si le dépôt local est modifié"; else ok "update refusé si le dépôt local est modifié"; fi
git -C "$DOTF_DIR" checkout -q -- links

out=$("$DOTF_DIR/bin/dotf" update 2>&1)
check "update : nouveau commit récupéré" grep -q 'config/test/a.conf' "$DOTF_DIR/links"
[ "$(readlink "$HOME/.config/a.conf")" = "$DOTF_DIR/config/test/a.conf" ] && ok "lien a.conf posé" || ko "lien a.conf" "$out"
[ "$(readlink "$HOME/.config/sub/b.conf")" = "$DOTF_DIR/config/test/b.conf" ] && ok "lien b.conf posé (dossier parent créé)" || ko "lien b.conf" "$out"
bk=$(find "$STATE/backup" -name a.conf 2>/dev/null | head -1)
[ -n "$bk" ] && [ "$(cat "$bk")" = "a d'origine" ] && ok "a.conf existant sauvegardé" || ko "sauvegarde de a.conf"

sed -i '/b.conf/d' "$REMOTE/links"
commit_remote "retrait de b"
"$DOTF_DIR/bin/dotf" update >/dev/null 2>&1
check "lien retiré de links : supprimé à l'update" test ! -e "$HOME/.config/sub/b.conf"

out=$("$DOTF_DIR/bin/dotf" status 2>&1)
case $out in *"à jour avec origin/main"*) ok "status : dépôt à jour" ;; *) ko "status" "$out" ;; esac

section "6b. Garde-fou anti-fuite"
G() { git -C "$DOTF_DIR" -c user.name=t -c user.email=t@t "$@"; }
try_commit() { # try_commit <contenu> : vrai si le commit est accepté
  printf '%s\n' "$1" >"$DOTF_DIR/fuite.txt"
  G add fuite.txt
  if G commit -qm test >/dev/null 2>&1; then return 0; fi
  G reset -q fuite.txt
  rm -f "$DOTF_DIR/fuite.txt"
  return 1
}
[ "$(G config --get core.hooksPath)" = .githooks ] && ok "hooks activés par dotf install" || ko "hooks activés"
printf '# test\nzorglub\nexemple-hote[0-9]+\n' >"$LOCAL/denylist"
priv="PRIVATE" # assemblé à l'exécution pour que ce fichier ne déclenche pas lui-même le garde-fou
try_commit "-----BEGIN OPENSSH $priv KEY-----" && ko "clé privée refusée" || ok "clé privée refusée"
try_commit "token: ghp_$(printf 'a%.0s' $(seq 36))" && ko "jeton GitHub refusé" || ok "jeton GitHub refusé" # dotf-allow
try_commit "password=hunter2hunter2" && ko "mot de passe en clair refusé" || ok "mot de passe en clair refusé" # dotf-allow
try_commit "cle=$(printf 'ab%.0s' $(seq 20))" && ko "longue chaîne hexadécimale refusée" || ok "longue chaîne hexadécimale refusée"
try_commit "Host serveur.ZorGlub" && ko "liste noire : insensible à la casse" || ok "liste noire : insensible à la casse" # dotf-allow
try_commit "ssh exemple-hote42" && ko "liste noire : motif regex" || ok "liste noire : motif regex" # dotf-allow
try_commit 'password="$MOT_DE_PASSE"' && ok "variable shell non signalée" || ko "variable shell signalée à tort"
G rm -q fuite.txt && G commit -qm nettoyage
try_commit "zorglubien" && ok "liste noire : mots entiers seulement" || ko "liste noire : mot partiel signalé à tort"
G rm -q fuite.txt && G commit -qm nettoyage
try_commit "Host zorglub  # dotf-allow" && ok "dotf-allow laisse passer la ligne" || ko "dotf-allow"
printf 'zorglub\n' >"$DOTF_DIR/fuite.txt" # dotf-allow
G add fuite.txt && G commit -q --no-verify -m "fuite forcée"
if G push -q origin HEAD:refs/heads/fuite >/dev/null 2>&1; then ko "pre-push bloque un commit fait avec --no-verify"; else ok "pre-push bloque un commit fait avec --no-verify"; fi
G reset -q --hard origin/main
out=$("$DOTF_DIR/bin/dotf" scan --all 2>&1) && ok "dotf scan --all : dépôt propre" || ko "dotf scan --all" "$out"
out=$("$DOTF_DIR/bin/dotf" status 2>&1)
case $out in *"liste noire : 2 motif(s)"*) ok "status : liste noire comptée" ;; *) ko "status : liste noire" "$out" ;; esac

section "6c. URL de push et vérification des mises à jour"
echo 'DOTF_PUSH_URL="git@example.invalid:moi/dotfiles.git"' >>"$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
[ "$(G config --get remote.origin.pushurl)" = "git@example.invalid:moi/dotfiles.git" ] && ok "DOTF_PUSH_URL appliquée" || ko "DOTF_PUSH_URL"
sed -i '/^DOTF_PUSH_URL=/d' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
[ -z "$(G config --get remote.origin.pushurl)" ] && ok "DOTF_PUSH_URL retirée : pushurl supprimée" || ko "retrait de pushurl"

check "horodatage de la vérification créé par un shell interactif" test -f "$STATE/last-fetch"
echo "maj 1" >"$REMOTE/maj.txt" && commit_remote "maj 1"
rm -f "$STATE/last-fetch"
run_shell zsh -ic 'true' >/dev/null
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(G rev-parse origin/main)" = "$(git -C "$REMOTE" rev-parse HEAD)" ] && break
  sleep 0.5
done
[ "$(G rev-parse origin/main)" = "$(git -C "$REMOTE" rev-parse HEAD)" ] && ok "fetch lancé en arrière-plan" || ko "fetch en arrière-plan"
r=$(run_shell bash -ic 'true')
case $r in *"1 mise(s) à jour disponible(s)"*) ok "mise à jour signalée à l'ouverture du shell" ;; *) ko "mise à jour signalée" "$r" ;; esac
stderr_clean && ok "aucune erreur pendant la vérification" || ko "erreurs pendant la vérification" "$(cat "$T/stderr.f")"
echo 'DOTF_UPDATE_CHECK=0' >>"$LOCAL/config.sh"
r=$(run_shell zsh -ic 'true')
[ -z "$r" ] && ok "DOTF_UPDATE_CHECK=0 : rien d'affiché" || ko "DOTF_UPDATE_CHECK=0" "$r"
sed -i '/^DOTF_UPDATE_CHECK=/d' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" update >/dev/null 2>&1
r=$(run_shell zsh -ic 'true')
[ -z "$r" ] && ok "après dotf update : plus de message" || ko "message après update" "$r"

section "7. Désinstallation"
"$DOTF_DIR/bin/dotf" uninstall >/dev/null 2>&1
for f in .profile .bashrc .zshrc .bash_profile; do
  check "$f identique à l'original" cmp -s "$HOME/$f" "$T/orig/$f"
done
check ".zshenv (créé par dotf) supprimé" test ! -e "$HOME/.zshenv"
[ "$(cat "$HOME/.config/a.conf" 2>/dev/null)" = "a d'origine" ] && ! [ -L "$HOME/.config/a.conf" ] && ok "a.conf d'origine restauré" || ko "restauration de a.conf"
check "config locale conservée" test -f "$LOCAL/config.sh"
check "hooks désactivés" test -z "$(git -C "$DOTF_DIR" config --get core.hooksPath)"

section "8. Dépôt supprimé, lignes laissées en place"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
mv "$DOTF_DIR" "$T/dotf.moved"
run_shell bash -ic 'true'; rc=$?
[ $rc -eq 0 ] && stderr_clean && ok "bash démarre sans erreur" || ko "bash sans dépôt" "$(cat "$T/stderr.f")"
r=$(run_shell zsh -ic 'echo $?')
[ "$r" = 0 ] && stderr_clean && ok "zsh démarre sans erreur (statut 0)" || ko "zsh sans dépôt" "$r $(cat "$T/stderr.f")"
mv "$T/dotf.moved" "$DOTF_DIR"

section "9. Purge"
echo "sale" >>"$DOTF_DIR/links"
"$DOTF_DIR/bin/dotf" uninstall --purge >/dev/null 2>&1
check "purge refusée si modifications locales" test -d "$DOTF_DIR"
git -C "$DOTF_DIR" checkout -q -- links
"$DOTF_DIR/bin/dotf" uninstall --purge >/dev/null 2>&1
check "purge : dépôt supprimé" test ! -e "$DOTF_DIR"
check "purge : état supprimé" test ! -e "$STATE"
check "purge : config locale conservée" test -f "$LOCAL/config.sh"
check "purge : .bashrc identique à l'original" cmp -s "$HOME/.bashrc" "$T/orig/.bashrc"

section "10. shellcheck"
if [ -n "$SHELLCHECK" ]; then
  if out=$(cd "$SRC" && "$SHELLCHECK" -x install.sh bin/dotf lib/*.sh shell/env.sh shell/init.sh shell/rc.d/*.sh modules/*.sh tests/run.sh .githooks/* 2>&1); then ok "shellcheck"; else ko "shellcheck" "$out"; fi
  if out=$(cd "$SRC" && "$SHELLCHECK" -s bash shell/rc.d/*.bash 2>&1); then ok "shellcheck (bash)"; else ko "shellcheck (bash)" "$out"; fi
else
  printf '  - shellcheck absent, ignoré\n'
fi

printf '\n%d réussi(s), %d échec(s)\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
