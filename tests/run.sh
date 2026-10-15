#!/usr/bin/env bash
# Tests de bout en bout dans un HOME jetable, sur une copie de l'arbre de travail.
#   tests/run.sh                      hors ligne
#   DOTF_TEST_NETWORK=1 tests/run.sh  installe vraiment les modules
# shellcheck disable=SC2015,SC2016,SC2088
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

# --- Environnement isolé ---
export HOME="$T/home"
unset XDG_CONFIG_HOME XDG_STATE_HOME XDG_DATA_HOME ZDOTDIR DOTF DOTF_LOCAL DOTF_STATE STARSHIP_CONFIG
mkdir -p "$HOME"
BASE_PATH=/usr/local/bin:/usr/bin:/bin
if [ -z "${DOTF_TEST_NETWORK-}" ]; then
  # Pas de réseau : curl et wget factices.
  mkdir -p "$T/fakebin"
  printf '#!/bin/sh\nexit 1\n' >"$T/fakebin/curl"
  cp "$T/fakebin/curl" "$T/fakebin/wget"
  chmod +x "$T/fakebin/"*
  BASE_PATH="$T/fakebin:$BASE_PATH"
  export GIT_ALLOW_PROTOCOL=file # git : dépôts locaux seulement
fi
export PATH="$BASE_PATH"
DOTF_DIR="$HOME/.local/share/dotf"
LOCAL="$HOME/.config/dotf"
STATE="$HOME/.local/state/dotf"

# Shell propre ; stderr sans le bruit des shells interactifs sans terminal.
run_shell() { # run_shell <bash|zsh> <options> <commande>
  env -i HOME="$HOME" PATH="$BASE_PATH" TERM="${RUN_TERM:-xterm-256color}" "$1" "$2" "$3" 2>"$T/stderr"
  local rc=$?
  grep -v -e 'cannot set terminal process group' -e 'no job control' "$T/stderr" >"$T/stderr.f" || true
  return $rc
}
stderr_clean() { [ ! -s "$T/stderr.f" ]; }

# --- Dépôt « distant » : copie de l'arbre de travail ---
REMOTE="$T/remote"
mkdir -p "$REMOTE"
(cd "$SRC" && tar --exclude=.git -cf - .) | tar -C "$REMOTE" -xf -
sed -i '/^[^#]/d' "$REMOTE/modules/default" # socle vide : chaque test choisit ses modules
git -C "$REMOTE" init -q -b main
git -C "$REMOTE" -c user.name=t -c user.email=t@t add -A
git -C "$REMOTE" -c user.name=t -c user.email=t@t commit -qm init
commit_remote() { git -C "$REMOTE" -c user.name=t -c user.email=t@t add -A && git -C "$REMOTE" -c user.name=t -c user.email=t@t commit -qm "$1"; }

# --- Fichiers rc d'origine ---
printf '# bashrc d origine\nexport ORIG_BASHRC=1\n' >"$HOME/.bashrc"
printf '# zshrc d origine\nexport ORIG_ZSHRC=1\n' >"$HOME/.zshrc"
printf '# profile d origine\n' >"$HOME/.profile"
printf '[alias]\n\tst = status\n' >"$HOME/.gitconfig"
printf '" vimrc d origine\nlet g:orig_vimrc = 1\n' >"$HOME/.vimrc"
printf '! Xresources d origine\nXTerm*test: orig\n' >"$HOME/.Xresources"
printf '# tmux.conf d origine\nset -g @orig 1\n' >"$HOME/.tmux.conf"
mkdir -p "$HOME/.ssh" "$T/orig/.ssh"
printf 'Host perso\n  ServerAliveInterval 5\n' >"$HOME/.ssh/config"
printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrigineOrigineOrigineOrigineOrigineOrigine origine\n' >"$HOME/.ssh/authorized_keys" # dotf-allow
mkdir -p "$T/orig"
cp "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.gitconfig" "$HOME/.vimrc" "$HOME/.Xresources" "$HOME/.tmux.conf" "$T/orig/"
cp "$HOME/.ssh/config" "$HOME/.ssh/authorized_keys" "$T/orig/.ssh/"

# =============================================================================
section "1. Bootstrap (équivalent de curl | sh)"
out=$(cd "$T" && DOTF_REPO="$REMOTE" sh -c "$(cat "$REMOTE/install.sh")" 2>&1)
check "dépôt cloné dans ~/.local/share/dotf" test -d "$DOTF_DIR/.git"
check "config locale créée depuis local.example" test -f "$LOCAL/config.sh"
for f in .profile .bashrc .zshenv .zshrc; do
  check "$f branché" grep -q '# dotf-hook' "$HOME/$f"
done
check ".vimrc branché" grep -q '" dotf-hook' "$HOME/.vimrc"
check ".ssh/config branché (Match all + 2 Include)" test "$(grep -c "dotf-hook" "$HOME/.ssh/config")" = 3
check ".ssh/authorized_keys : passe-partout ajouté, clé d'origine gardée" test "$(grep -c 'passe-partout dotf-allow dotf-hook$' "$HOME/.ssh/authorized_keys")-$(grep -c ' origine$' "$HOME/.ssh/authorized_keys")" = 1-1
check ".tmux.conf branché" test "$(grep -c "^source-file -q .*dotf-hook" "$HOME/.tmux.conf")" = 2
check ".Xresources branché (2 inclusions protégées)" test "$(grep -c '^#include .*dotf-hook' "$HOME/.Xresources")" = 2
if [ -z "${DOTF_TEST_NETWORK-}" ]; then
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="starship"/' "$LOCAL/config.sh"
  out=$("$DOTF_DIR/bin/dotf" install 2>&1)
  case $out in *'starship : dernière version introuvable'*Terminé*) ok "hors ligne : échec du module signalé sans interrompre l'installation" ;; *) ko "échec du module signalé" "$out" ;; esac
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
fi

section "2. Idempotence"
mkdir -p "$T/after1"
cp "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshenv" "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.Xresources" "$HOME/.tmux.conf" "$T/after1/"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
for f in .profile .bashrc .zshenv .zshrc .vimrc .Xresources .tmux.conf; do
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
  [ "$r" = "_dotf_prompt;_dotf_theme;_dotf_title_prompt;_dotf_history_sync" ] && ok "bash : prompt de repli sans starship" || ko "bash : prompt de repli" "$r"
  r=$(run_shell zsh -ic 'echo "$PROMPT"')
  case $r in *'%n@%B%F{'*'}%m'*) ok "zsh : prompt de repli sans starship" ;; *) ko "zsh : prompt de repli" "$r" ;; esac
else
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="starship"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "starship installé dans ~/.local/bin" test -x "$HOME/.local/bin/starship"
  r=$(run_shell bash -ic 'echo "$PROMPT_COMMAND"')
  case $r in *starship*) ok "bash : prompt starship" ;; *) ko "bash : prompt starship" "$r" ;; esac
  r=$(run_shell bash -ic 'echo "$STARSHIP_PROMPT_COMMAND"')
  [ "$r" = "_dotf_theme;_dotf_title_prompt;_dotf_history_sync" ] && ok "bash : starship conserve titre et synchro de l'historique" || ko "bash : STARSHIP_PROMPT_COMMAND" "$r"
  r=$(run_shell zsh -ic 'echo "$STARSHIP_CONFIG"; grep "^style" "$STARSHIP_CONFIG"; echo "$DOTF_HOST_COLOR"')
  c=$(printf '%s\n' "$r" | sed -n 3p)
  [ "$(printf '%s\n' "$r" | sed -n 1p)" = "$HOME/.cache/dotf/starship-$c-local.toml" ] &&
    [ "$(printf '%s\n' "$r" | sed -n 2p)" = "style = \"bold $c\"" ] && ok "zsh : config starship avec la couleur de l'hôte" || ko "zsh : STARSHIP_CONFIG" "$r"
  r=$(run_shell bash -ic 'starship prompt' | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\\[][]//g')
  case $r in *"$(id -un) "*" $(uname -n) "*) stderr_clean && ok "bash : prompt starship avec utilisateur et hôte" || ko "bash : erreurs starship" "$(cat "$T/stderr.f")" ;; *) ko "bash : prompt starship" "$r" ;; esac
  r=$(RUN_TERM=dumb run_shell bash -ic 'echo "$PROMPT_COMMAND"')
  [ "$r" = "_dotf_prompt;_dotf_theme;_dotf_title_prompt;_dotf_history_sync" ] && stderr_clean && ok "TERM=dumb : prompt de repli malgré starship" || ko "TERM=dumb" "$r $(cat "$T/stderr.f")"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="zsh-autosuggestions zsh-syntax-highlighting"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  r=$(run_shell zsh -ic 'print $+functions[_zsh_autosuggest_start] $+functions[_zsh_highlight]')
  [ "$r" = "1 1" ] && stderr_clean && ok "zsh : autosuggestions et coloration syntaxique chargées" || ko "zsh : plugins" "$r $(cat "$T/stderr.f")"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="gitleaks"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "module retiré de DOTF_MODULES : starship désinstallé" test ! -e "$HOME/.local/bin/starship" -a ! -e "$HOME/.local/opt/starship"
  check "gitleaks installé dans ~/.local/bin" "$HOME/.local/bin/gitleaks" version
  out=$("$DOTF_DIR/bin/dotf" status 2>&1)
  case $out in *"gitleaks utilisé en complément"*) ok "status : gitleaks détecté hors PATH" ;; *) ko "status : gitleaks" "$out" ;; esac
  out=$("$DOTF_DIR/bin/dotf" update 2>&1)
  case $out in *"gitleaks "*" à jour"*) ok "update : module gitleaks mis à jour" ;; *) ko "update gitleaks" "$out" ;; esac
  # Clé Stripe factice : inconnue des règles intégrées, reconnue par gitleaks.
  printf 'stripe = "sk_%s_%s"\n' live 4eC39HqLyjWDarjtT1zdp7dc >"$DOTF_DIR/fuite.txt"
  git -C "$DOTF_DIR" add fuite.txt
  if git -C "$DOTF_DIR" -c user.name=t -c user.email=t@t commit -qm t >/dev/null 2>&1; then ko "hook : gitleaks bloque une clé Stripe"; else ok "hook : gitleaks bloque une clé Stripe"; fi
  git -C "$DOTF_DIR" reset -q fuite.txt; rm -f "$DOTF_DIR/fuite.txt"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "gitleaks désinstallé quand retiré de DOTF_MODULES" test ! -e "$HOME/.local/bin/gitleaks"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="broot difftastic dust gitui"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  for b in broot difft dust gitui; do check "$b installé" "$HOME/.local/bin/$b" --version; done
  r=$(run_shell zsh -ic 'whence -w br; print ${_comps[broot]} ${_comps[dust]}')
  [ "$r" = "br: function
_broot _dust" ] && stderr_clean && ok "zsh : br et complétions broot, dust" || ko "zsh : br/complétions" "$r $(cat "$T/stderr.f")"
  r=$(run_shell bash -ic 'type -t br; complete -p broot dust | wc -l')
  [ "$r" = "function
2" ] && stderr_clean && ok "bash : br et complétions broot, dust" || ko "bash : br/complétions" "$r $(cat "$T/stderr.f")"
  check "broot ne propose pas d'écrire br dans les rc" test -e "$HOME/.config/broot/launcher/installed-v5"
  git init -q "$T/dft" && printf 'a = 1\n' >"$T/dft/f.py" && git -C "$T/dft" add f.py
  printf 'a = 2\n' >"$T/dft/f.py"
  r=$(PATH="$HOME/.local/bin:$PATH" git -C "$T/dft" -c core.pager=cat ddiff 2>&1 | head -n 1)
  [ "$r" = "f.py --- Python" ] && ok "git ddiff passe par difft" || ko "git ddiff" "$r"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="catppuccin vim-catppuccin vim-lightline"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  r=$(env -i HOME="$HOME" PATH="$BASE_PATH" vim -n -i NONE -es -u "$HOME/.vimrc" -c 'call writefile([g:colors_name, exists("g:loaded_lightline"), g:lightline.colorscheme, &laststatus], "/dev/stdout")' -c 'qa!' </dev/null)
  [ "$r" = "catppuccin_mocha
1
catppuccin_mocha
2" ] && ok "vim : catppuccin mocha, lightline aux mêmes couleurs" || ko "vim : modules" "$r"
  "$DOTF_DIR/bin/dotf" theme >/dev/null 2>&1
  r=$(env -i HOME="$HOME" PATH="$BASE_PATH" vim -n -i NONE -es -u "$HOME/.vimrc" -c 'call writefile([g:colors_name], "/dev/stdout")' -c 'qa!' </dev/null)
  [ "$r" = catppuccin_latte ] && ok "vim : latte après « dotf theme »" || ko "vim : bascule" "$r"
  r=$(env -i HOME="$HOME" PATH="$BASE_PATH" vim -n -i NONE -es -u "$HOME/.vimrc" -c "call system('$DOTF_DIR/bin/dotf theme')" -c 'doautocmd SigUSR1' -c 'call writefile([g:colors_name, g:lightline.colorscheme], "/dev/stdout")' -c 'qa!' </dev/null)
  [ "$r" = "catppuccin_mocha
catppuccin_mocha" ] && ok "vim ouvert : thème et lightline rechargés sur SigUSR1" || ko "vim : SigUSR1" "$r"
  "$DOTF_DIR/bin/dotf" theme light >/dev/null 2>&1
  r=$(run_shell zsh -ic 'print ${ZSH_HIGHLIGHT_STYLES[comment]}; type gitui broot | grep -c function; dotf theme dark >/dev/null; _dotf_theme; print ${ZSH_HIGHLIGHT_STYLES[comment]}')
  [ "$r" = "fg=#acb0be
2
fg=#585b70" ] && stderr_clean && ok "zsh : coloration latte puis mocha sans relancer, gitui et broot habillés" || ko "zsh : catppuccin" "$r $(cat "$T/stderr.f")"
  "$DOTF_DIR/bin/dotf" theme light >/dev/null 2>&1
  if command -v script >/dev/null 2>&1; then
    r=$(env -i HOME="$HOME" PATH="$BASE_PATH" TERM=xterm-256color script -qec "bash -ic 'echo; _dotf_theme'" /dev/null </dev/null | grep -ao $'\e]11;#[0-9a-f]*' | tr -d '\033' | sort | uniq -c | tr -s ' ')
    [ "$r" = " 2 ]11;#eff1f5" ] && ok "terminal : fond latte envoyé au démarrage et à chaque prompt" || ko "terminal : palette" "$r"
  fi
  "$DOTF_DIR/bin/dotf" theme dark >/dev/null 2>&1
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="nerd-fonts"\nDOTF_FONTS="FiraCode"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  r=$(fc-list : family 2>/dev/null | cut -d, -f1 | grep -i 'firacode' | sort -u)
  [ "$r" = "FiraCode Nerd Font Mono" ] && ok "nerd-fonts : FiraCode Mono visible (fc-list), sans les autres variantes" || ko "nerd-fonts" "$r"
  sed -i -e 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' -e '/^DOTF_FONTS=/d' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "nerd-fonts : lien des polices retiré" test ! -e "$HOME/.local/share/fonts/NerdFonts" -a ! -L "$HOME/.local/share/fonts/NerdFonts"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="nvim catppuccin vim-catppuccin vim-lightline"/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "nvim : branché dès la première installation du module" grep -q 'dotf-hook' "$HOME/.config/nvim/init.vim"
  "$DOTF_DIR/bin/dotf" theme dark >/dev/null 2>&1
  r=$(cd "$T" && env -i HOME="$HOME" PATH="$BASE_PATH" "$HOME/.local/bin/nvim" --headless -n -i NONE nv.dgibi +'call writefile([g:colors_name, &ft, v:errmsg], "/dev/stdout")' +'qa!' 2>&1)
  [ "$r" = "catppuccin_mocha
gibiane" ] && ok "nvim : vimrc commun (thème, types de fichiers), sans erreur" || ko "nvim" "$r"
  sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
  check "nvim désinstallé" test ! -e "$HOME/.local/bin/nvim" -a ! -L "$HOME/.local/bin/nvim"
  check "broot : marqueur de br retiré" test ! -e "$HOME/.config/broot/launcher"
  check "broot, difft, dust, gitui désinstallés" test ! -e "$HOME/.local/bin/broot" -a ! -e "$HOME/.local/bin/difft" -a ! -e "$HOME/.local/bin/dust" -a ! -e "$HOME/.local/bin/gitui"
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

r=$(run_shell zsh -ic 'bindkey -lL main; print $KEYTIMEOUT; bindkey -M viins "^[OA"; bindkey -M vicmd v; bindkey -M vicmd k; zstyle -L ":completion:*:*:kill:*" menu')
[ "$r" = 'bindkey -A viins main
1
"^[OA" up-line-or-beginning-search
"v" edit-command-line
"k" up-line-or-beginning-search
zstyle '"':completion:*:*:kill:*'"' menu yes select' ] && stderr_clean && ok "zsh : mode vi, ↑ par préfixe, v → éditeur, menu de kill" || ko "zsh : clavier" "$r $(cat "$T/stderr.f")"
r=$(run_shell bash -ic 'shopt -oq vi && echo vi; bind -m vi-insert -p | grep -F "\\M-[A\""; bind -m vi-command -p | grep -F "\"k\""')
[ "$r" = 'vi
"\M-[A": history-search-backward
"k": history-search-backward' ] && stderr_clean && ok "bash : mode vi, ↑ et k par préfixe" || ko "bash : clavier" "$r $(cat "$T/stderr.f")"

# Module joplin : ne remplace jamais un ~/.local/bin/joplin qui n'est pas le sien.
mkdir -p "$HOME/.local/bin"
echo autre >"$HOME/.local/bin/joplin"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="joplin"/' "$LOCAL/config.sh"
out=$("$DOTF_DIR/bin/dotf" install 2>&1)
case $out in *"joplin : ~/.local/bin/joplin existe déjà"*) ok "joplin : refuse d'écraser un autre joplin" ;; *) ko "joplin : écrasement" "$out" ;; esac
check "joplin : fichier existant intact" grep -qx autre "$HOME/.local/bin/joplin"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
check "joplin : fichier existant intact après retrait du module" grep -qx autre "$HOME/.local/bin/joplin"
rm -f "$HOME/.local/bin/joplin"

section "5e. Couleur d'hôte, titre, environnement, profils, kpsync"
r=$(run_shell bash -ic 'echo $DOTF_HOST_COLOR'; run_shell zsh -ic 'echo $DOTF_HOST_COLOR')
c=$(printf '%s\n' "$r" | head -n 1)
case $c in [1-6] | 9 | 1[0-4]) [ "$(printf '%s\n' "$r" | sort -u | wc -l)" = 1 ] && ok "couleur d'hôte $c, la même en bash et zsh" || ko "couleur d'hôte différente" "$r" ;; *) ko "couleur d'hôte" "$r" ;; esac
r=$(run_shell zsh -ic 'cd; _dotf_title_precmd; setTitle fixe; _dotf_title_precmd; setTitle; _dotf_title_precmd' | od -An -c | tr -d ' \n')
h=$(uname -n | cut -d. -f1)
case $r in *"033]0;$h:~\\a033]0;fixe\\a033]0;\\a033]0;$h:~\\a"*) ok "titre automatique, setTitle le fixe puis le libère" ;; *) ko "titre" "$r" ;; esac
mkdir -p "$HOME/bin"
r=$(run_shell bash -lc 'echo "$EDITOR $VISUAL"; case :$PATH: in *:$HOME/bin:*) echo bin ;; esac')
e='vi'; command -v vim >/dev/null && e='vim'
[ "$r" = "$e $e
bin" ] && ok "EDITOR=$e, ~/bin dans le PATH" || ko "env" "$r"
echo 'DOTF_PROFILES="nfs-home"' >>"$LOCAL/config.sh"
r=$(run_shell bash -lc 'echo "$XDG_CACHE_HOME"')
[ "$r" = "/tmp/$(id -un)/.cache" ] && ok "profil nfs-home : cache sur le disque local" || ko "profil nfs-home" "$r"
sed -i '/^DOTF_PROFILES=/d' "$LOCAL/config.sh"
echo distant >"$T/remote-file"; echo local >"$T/local-file"; touch -d '2000-01-01' "$T/local-file"
printf 'KPSYNC_LOCAL=%s\nKPSYNC_REMOTE=%s\n' "$T/local-file" "$T/remote-file" >>"$LOCAL/config.sh"
"$DOTF_DIR/bin/kpsync" >/dev/null 2>&1
[ "$(cat "$T/local-file")" = distant ] && [ "$(cat "$T/local-file~")" = local ] && ok "kpsync : la version récente gagne, l'ancienne est gardée" || ko "kpsync"
sed -i '/^KPSYNC_/d' "$LOCAL/config.sh"

section "5f. Git"
r=$(git config --global --includes user.email)
[ "$r" = gauthier12@users.noreply.github.com ] && ok "git : adresse générique GitHub par défaut" || ko "git : adresse" "$r"
r=$(git config --global --includes user.name; git config --global --includes pull.ff; git config --global alias.st)
[ "$r" = "Gauthier
only
status" ] && ok "git : config du dépôt incluse, config existante conservée" || ko "git : inclusion" "$r"
printf '[user]\n\tname = Autre\n' >"$LOCAL/gitconfig"
r=$(git config --global --includes user.name)
[ "$r" = Autre ] && ok "git : la config locale a le dernier mot" || ko "git : surcharge locale" "$r"
rm "$LOCAL/gitconfig"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
[ "$(git config --global --get-all include.path | grep -c "$DOTF_DIR/config/git/config")" = 1 ] && ok "git : inclusion ajoutée une seule fois" || ko "git : inclusion en double"

section "5g. Options zsh"
r=$(run_shell zsh -ic 'print $options[interactivecomments] $options[beep] $options[histreduceblanks]; whence -w zmv; print ${widgets[self-insert]} ${widgets[bracketed-paste]}; bindkey -M viins "^Z"')
[ "$r" = 'on off on
zmv: function
user:url-quote-magic user:bracketed-paste-magic
"^Z" _dotf_fg' ] && stderr_clean && ok "zsh : commentaires, sans bip, zmv, URL protégées, Ctrl-Z → fg" || ko "zsh : options" "$r $(cat "$T/stderr.f")"

section "5h. vim"
mkdir -p "$T/vim"
printf "* commentaire\nSI (A > 1);\nREPE B 3;\nX = 1;\nFIN B;\nSINON;\nY = 2;\nFINSI;\n'SI' (A < 0); Z = 3; 'FINSI';\nW = 4;\n" >"$T/vim/t.dgibi"
echo 'C fixe' >"$T/vim/t.eso"
echo 'G01 X1 (coupe)' >"$T/vim/t.nc"
cat >"$T/vim/probe.vim" <<'VIM'
let out = [g:colors_name, exists('g:orig_vimrc'), maparg('<F9>', 'n'), &ignorecase . &smartcase . &shiftwidth, 'mouse=' . &mouse]
for f in ['t.dgibi', 't.eso', 't.nc']
  execute 'edit!' f
  call add(out, &filetype)
endfor
edit! t.dgibi
normal! gg=G
call add(out, join(map(getline(1, '$'), 'indent(v:key + 1)'), ','))
setlocal spell spelllang=fr
spellgood motajoute
let n = len(split(&runtimepath, ','))
source ~/.vimrc
call add(out, n == len(split(&runtimepath, ',')))
call writefile(out, 'out')
qa!
VIM
(cd "$T/vim" && env -i HOME="$HOME" PATH="$BASE_PATH" vim -n -i NONE -es -u "$HOME/.vimrc" -S probe.vim </dev/null)
r=$(cat "$T/vim/out" 2>/dev/null)
[ "$r" = "habamax
1
:set number!<CR>
103
mouse=a
gibiane
fortran
gcode
0,0,4,8,4,0,4,0,0,0
1" ] && ok "vim : thème de repli, vimrc d'origine gardé, F9, souris, types de fichiers, indentation Gibiane" || ko "vim" "$r"
check "vim : mot ajouté dans la config locale, pas dans le dépôt" test -f "$LOCAL/vim/spell/fr.utf-8.add" -a ! -e "$DOTF_DIR/config/vim/spell/fr.utf-8.add"

section "5i. Ressources X"
if command -v cpp >/dev/null 2>&1; then
  printf 'URxvt*font: xft:Local:size=13\n' >"$LOCAL/Xresources"
  r=$(cpp -P "$HOME/.Xresources" 2>&1 | grep -E 'test|URxvt\*font')
  [ "$r" = "XTerm*test: orig
URxvt*font: xft:Hasklug Nerd Font Mono:size=11
URxvt*font: xft:Local:size=13" ] && ok "Xresources : d'origine, puis dépôt, puis local (prioritaire)" || ko "Xresources" "$r"
  rm "$LOCAL/Xresources"
else
  ok "Xresources : cpp absent, test sauté"
fi

section "5j. Thème"
"$DOTF_DIR/bin/dotf" theme >/dev/null 2>&1
r=$(cat "$STATE/theme"; run_shell bash -ic 'echo $DOTF_THEME'; "$DOTF_DIR/bin/dotf" theme >/dev/null 2>&1; run_shell zsh -ic 'echo $DOTF_THEME')
[ "$r" = "latte
latte
mocha" ] && ok "dotf theme : bascule mocha → latte → mocha, lue par bash et zsh" || ko "dotf theme" "$r"
r=$(env -i HOME="$HOME" PATH="$BASE_PATH" SSH_CONNECTION='1 2 3 4' LC_DOTF_THEME=latte bash -ic 'echo $DOTF_THEME $DOTF_THEME_SSH' 2>/dev/null
  env -i HOME="$HOME" PATH="$BASE_PATH" LC_DOTF_THEME=latte bash -ic 'echo $DOTF_THEME $LC_DOTF_THEME' 2>/dev/null)
[ "$r" = "latte latte
mocha mocha" ] && ok "thème : session ssh sur celui du poste ; hors ssh, LC_DOTF_THEME suit la machine" || ko "LC_DOTF_THEME" "$r"
r=$(ssh -F "$HOME/.ssh/config" -G perso 2>/dev/null | grep -E '^(sendenv LC_DOTF|serveraliveinterval|controlmaster)' | sort)
[ "$r" = "controlmaster auto
sendenv LC_DOTF_COLORTERM
sendenv LC_DOTF_THEME
serveraliveinterval 5" ] && ok "ssh : réglages communs après ceux de ~/.ssh/config, thème envoyé" || ko "ssh -G" "$r"
out=$(DOTF_THEME_SSH=latte "$DOTF_DIR/bin/dotf" theme 2>&1)
case $out in *"suit le thème du poste"*) ok "dotf theme prévient quand la session suit le poste" ;; *) ko "dotf theme sous LC_DOTF_THEME" "$out" ;; esac
"$DOTF_DIR/bin/dotf" theme frappe >/dev/null 2>&1
r=$(run_shell zsh -ic 'echo $DOTF_THEME'; echo 'DOTF_THEME_DARK=macchiato' >>"$LOCAL/config.sh"
  "$DOTF_DIR/bin/dotf" theme >/dev/null 2>&1; cat "$STATE/theme"; "$DOTF_DIR/bin/dotf" theme >/dev/null 2>&1; cat "$STATE/theme")
[ "$r" = "frappe
latte
macchiato" ] && ok "dotf theme : variante choisie, bascule vers DOTF_THEME_DARK" || ko "dotf theme variantes" "$r"
sed -i '/^DOTF_THEME_DARK=/d' "$LOCAL/config.sh"
r=$("$DOTF_DIR/bin/dotf" theme list 2>&1)
[ "$r" = "  latte
  frappe
* macchiato
  mocha" ] && ok "dotf theme list : de la plus claire à la plus sombre, actuelle marquée" || ko "dotf theme list" "$r"
mkdir -p "$T/xfbin" "$HOME/.local/opt/catppuccin-xfce"
printf '#!/bin/sh\necho "$*" >>"$HOME/xfconf.log"\n' >"$T/xfbin/xfconf-query" && chmod +x "$T/xfbin/xfconf-query"
PATH="$T/xfbin:$PATH" "$DOTF_DIR/bin/dotf" theme latte >/dev/null 2>&1
r=$(cut -d ' ' -f 4,9 "$HOME/xfconf.log" 2>&1)
[ "$r" = "/Net/ThemeName catppuccin-latte-mauve-standard+default
/Gtk/CursorThemeName catppuccin-latte-dark-cursors" ] && ok "dotf theme : XFCE (GTK, curseur) suit" || ko "XFCE" "$r"
rm -rf "$HOME/xfconf.log" "$HOME/.local/opt/catppuccin-xfce"
if "$DOTF_DIR/bin/dotf" theme mauve >/dev/null 2>&1; then ko "dotf theme : variante inconnue acceptée"; else ok "dotf theme : variante inconnue refusée"; fi
"$DOTF_DIR/bin/dotf" theme dark >/dev/null 2>&1
if command -v tmux >/dev/null 2>&1; then
  r=$(tmux -L "dotf$$" -f "$HOME/.tmux.conf" start-server \; show -s terminal-features \; show -g @orig \; kill-server 2>&1 | grep -c 'xterm-256color:RGB\|@orig 1')
  [ "$r" = 2 ] && ok "tmux : config d'origine et couleurs 24 bits" || ko "tmux" "$r"
fi

section "5k. kitty et couleurs 24 bits"
mkdir -p "$T/kittybin"
printf '#!/bin/sh\n' >"$T/kittybin/kitty" && chmod +x "$T/kittybin/kitty"
PATH="$T/kittybin:$PATH" "$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
r=$(cat "$HOME/.config/kitty/kitty.conf" 2>&1)
[ "$r" = "include $DOTF_DIR/config/kitty/dotf-hook.conf" ] && [ -f "$DOTF_DIR/config/kitty/dotf-hook.conf" ] &&
  ok "kitty présent : kitty.conf branché" || ko "kitty.conf" "$r"
if command -v infocmp >/dev/null 2>&1; then
  check "terminfo xterm-kitty connu (~/.terminfo)" env HOME="$HOME" infocmp xterm-kitty
fi
r=$(env -i HOME="$HOME" PATH="$BASE_PATH" SSH_CONNECTION='1 2 3 4' LC_DOTF_COLORTERM=truecolor bash -lc 'echo $COLORTERM' 2>/dev/null)
[ "$r" = truecolor ] && ok "ssh : COLORTERM du poste repris" || ko "COLORTERM en ssh" "$r"
echo 'DOTF_TRUECOLOR=1' >>"$LOCAL/config.sh"
r=$(env -i HOME="$HOME" PATH="$BASE_PATH" COLORTERM=rxvt-xpm zsh -lc 'echo $COLORTERM $LC_DOTF_COLORTERM' 2>/dev/null)
sed -i '/^DOTF_TRUECOLOR=/d' "$LOCAL/config.sh"
[ "$r" = "truecolor truecolor" ] && ok "DOTF_TRUECOLOR=1 : 24 bits forcé, transmis en ssh" || ko "DOTF_TRUECOLOR" "$r"

section "5d. Moteur des modules (module factice, hors ligne)"
cat >"$DOTF_DIR/modules/fake.sh" <<'MOD'
# shellcheck shell=sh disable=SC2034
pkg_bins="bin/fake"
pkg_latest() { cat "$HOME/fake-version"; }
pkg_install() { mkdir bin && printf '#!/bin/sh\necho fake %s\n' "$1" >bin/fake && chmod +x bin/fake; }
MOD
echo 1.0 >"$HOME/fake-version"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="fake"/' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
r=$("$HOME/.local/bin/fake" 2>&1)
[ "$r" = "fake 1.0" ] && ok "install : version 1.0, lien dans ~/.local/bin" || ko "install fake" "$r"
echo 2.0 >"$HOME/fake-version"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
r=$("$HOME/.local/bin/fake")
[ "$r" = "fake 1.0" ] && ok "install : ne met pas à jour" || ko "install a mis à jour" "$r"
out=$("$DOTF_DIR/bin/dotf" install --update 2>&1)
r=$("$HOME/.local/bin/fake")
[ "$r" = "fake 2.0" ] && ok "install --update : passe en 2.0" || ko "update fake" "$r $out"
out=$("$DOTF_DIR/bin/dotf" install --update 2>&1)
case $out in *"fake 2.0 à jour"*) ok "update : rien à faire si déjà à jour" ;; *) ko "update à jour" "$out" ;; esac
out=$("$DOTF_DIR/bin/dotf" status 2>&1)
case $out in *"fake 2.0"*) ok "status : version affichée" ;; *) ko "status fake" "$out" ;; esac
case $out in *_template*) ko "status : le modèle est listé" "$out" ;; *) ok "status : le modèle n'est pas listé" ;; esac
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="_template"/' "$LOCAL/config.sh"
out=$("$DOTF_DIR/bin/dotf" install 2>&1)
case $out in *"_template : module inconnu"*) ok "le modèle ne s'installe pas" ;; *) ko "modèle installable" "$out" ;; esac
cat >"$DOTF_DIR/modules/fake-dep.sh" <<'MOD'
# shellcheck shell=sh disable=SC2034
pkg_needs="fake"
pkg_latest() { echo 1; }
pkg_install() { echo 'export T_FAKE_ENV=ok' >.env.sh; }
pkg_update() { echo maj >>updated; }
pkg_remove() { if [ -d "$HOME/.local/opt/fake" ]; then touch "$HOME/fake-dep-removed"; fi; }
MOD
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="fake-dep"/' "$LOCAL/config.sh"
out=$("$DOTF_DIR/bin/dotf" install 2>&1)
check "dépendance : fake installé avant fake-dep" test -x "$HOME/.local/bin/fake" -a -d "$HOME/.local/opt/fake-dep"
r=$(run_shell bash -lc 'echo "${T_FAKE_ENV-}"')
[ "$r" = ok ] && ok ".env.sh du module chargé par les shells" || ko ".env.sh" "$r"
"$DOTF_DIR/bin/dotf" install --update >/dev/null 2>&1
[ "$(cat "$HOME/.local/opt/fake-dep/updated" 2>/dev/null)" = maj ] && ok "pkg_update : mise à jour sur place" || ko "pkg_update"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
check "pkg_remove appelé, avant le retrait de la dépendance" test -e "$HOME/fake-dep-removed"
rm -f "$HOME/fake-dep-removed"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="fake-dep"/' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
echo fake >>"$DOTF_DIR/modules/default"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
out=$("$DOTF_DIR/bin/dotf" install 2>&1)
case $out in *"Modules (fake)"*) check "socle : module de modules/default installé" test -x "$HOME/.local/bin/fake" ;; *) ko "socle" "$out" ;; esac
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES="-fake fake-dep"/' "$LOCAL/config.sh"
out=$("$DOTF_DIR/bin/dotf" install 2>&1)
case $out in *"Modules (fake-dep)"*) ok "DOTF_MODULES : -nom retire du socle, nom ajoute" ;; *) ko "écart local" "$out" ;; esac
git -C "$DOTF_DIR" checkout -q modules/default
rm "$DOTF_DIR/modules/fake.sh" "$DOTF_DIR/modules/fake-dep.sh"
sed -i 's/^DOTF_MODULES=.*/DOTF_MODULES=""/' "$LOCAL/config.sh"
"$DOTF_DIR/bin/dotf" install >/dev/null 2>&1
check "modules retirés (et supprimés du dépôt) : désinstallés" test ! -e "$HOME/.local/bin/fake" -a ! -e "$HOME/.local/opt/fake" -a ! -e "$HOME/.local/opt/fake-dep"
rm -f "$HOME/fake-version"

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
for f in .profile .bashrc .zshrc .bash_profile .gitconfig .vimrc .Xresources .tmux.conf .ssh/config .ssh/authorized_keys; do
  check "$f identique à l'original" cmp -s "$HOME/$f" "$T/orig/$f"
done
check ".zshenv (créé par dotf) supprimé" test ! -e "$HOME/.zshenv"
check "kitty.conf (créé par dotf) supprimé" test ! -e "$HOME/.config/kitty/kitty.conf"
check "terminfo xterm-kitty retiré" test ! -e "$HOME/.terminfo/x/xterm-kitty"
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
if command -v cpp >/dev/null 2>&1; then
  check "Xresources lisible sans erreur" sh -c 'cpp -P "$1" >/dev/null 2>&1' _ "$HOME/.Xresources"
fi
check "vim démarre sans erreur" env -i HOME="$HOME" PATH="$BASE_PATH" vim -n -i NONE -es -u "$HOME/.vimrc" -c q </dev/null
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
  if out=$(cd "$SRC" && "$SHELLCHECK" -x install.sh bin/dotf lib/*.sh shell/env.sh shell/init.sh shell/rc.d/*.sh modules/*.sh scripts/*.sh tests/run.sh .githooks/* 2>&1); then ok "shellcheck"; else ko "shellcheck" "$out"; fi
  if out=$(cd "$SRC" && "$SHELLCHECK" -s bash shell/rc.d/*.bash 2>&1); then ok "shellcheck (bash)"; else ko "shellcheck (bash)" "$out"; fi
else
  printf '  - shellcheck absent, ignoré\n'
fi

printf '\n%d réussi(s), %d échec(s)\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
