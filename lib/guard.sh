# shellcheck shell=sh
# Garde-fou anti-fuite : hooks git pre-commit et pre-push qui cherchent secrets et données personnelles.
# Règles : celles ci-dessous, la liste noire locale $DOTF_LOCAL/denylist, et gitleaks s'il est là.
# Une ligne contenant « dotf-allow » est ignorée.

# nom<TAB>options<TAB>ERE ; options : i insensible à la casse, w mot entier.
_guard_rules() {
  cat <<'EOF'
cle-privee	-	-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY( BLOCK)?-----
cle-publique-ssh	-	(ssh-(rsa|ed25519|dss)|ecdsa-sha2-nistp[0-9]+) AAAA[A-Za-z0-9+/]{20,}
jeton-github	-	(gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,})
jeton-gitlab	-	glpat-[A-Za-z0-9_-]{20}
cle-aws	-	(AKIA|ASIA)[0-9A-Z]{16}
jeton-slack	-	xox[abposr]-[A-Za-z0-9-]{10,}
affectation-secrete	i	(pass(word|wd)?|secret|token|api_?key)["']?[[:space:]]*[:=][[:space:]]*["']?[^$[:space:]"'][^[:space:]"']{7,}
hexa-long	-	[0-9a-fA-F]{32,}
EOF
  if [ -r "$DOTF_LOCAL/denylist" ]; then
    awk '{ sub(/[ \t]*#.*/, ""); gsub(/^[ \t]+|[ \t]+$/, ""); if ($0 != "") print "liste-noire\tiw\t" $0 }' "$DOTF_LOCAL/denylist"
  fi
}

# --- Lignes à vérifier : fichier<TAB>n° de ligne<TAB>texte ---

# Lignes ajoutées d'un diff -U0 ; « @commit <sha> » préfixe les noms de fichiers.
_guard_parse_diff() {
  awk '
    /^@commit / { c = $2 ":"; next }
    /^\+\+\+ / { f = substr($0, 5); sub(/^b\//, "", f); next }
    /^@@/ { match($0, /\+[0-9]+/); n = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
    /^\+/ { printf "%s%s\t%d\t%s\n", c, f, n, substr($0, 2); n++ }
  '
}

_guard_lines_staged() {
  git -C "$DOTF" diff --cached -U0 --no-color --no-ext-diff --diff-filter=ACMR | _guard_parse_diff
}

_guard_lines_range() { # arguments de git log, ex. A..B
  git -C "$DOTF" log -p -U0 --no-color --no-ext-diff -m --first-parent --format='@commit %h' "$@" | _guard_parse_diff
}

_guard_lines_all() {
  git -C "$DOTF" ls-files -z --cached --others --exclude-standard |
    (cd "$DOTF" && xargs -0 grep -I -l -e '' -- 2>/dev/null) |
    while IFS= read -r _f; do
      awk -v f="$_f" '{ printf "%s\t%d\t%s\n", f, FNR, $0 }' "$DOTF/$_f"
    done
}

# --- Recherche ---

# Lit les lignes sur l'entrée, affiche les trouvailles, code 1 s'il y en a.
# grep -E et non awk : mawk (Debian) gère mal {n,}.
_guard_match() {
  _tmp=$(mktemp -d)
  cat >"$_tmp/in"
  cut -f3- "$_tmp/in" >"$_tmp/text"
  : >"$_tmp/hits"
  _guard_rules | while IFS="$TAB" read -r _name _opts _re; do
    set --
    case $_opts in *i*) set -- "$@" -i ;; esac
    case $_opts in *w*) set -- "$@" -w ;; esac
    grep -nE "$@" -e "$_re" "$_tmp/text" 2>/dev/null | cut -d: -f1 | sed "s/\$/$TAB$_name/" >>"$_tmp/hits"
  done
  # Première règle trouvée pour chaque ligne.
  awk -F '\t' '
    NR == FNR { if (!($1 in rule)) rule[$1] = $2; next }
    (FNR in rule) {
      text = $0; sub(/^[^\t]*\t[^\t]*\t/, "", text)
      if (index(text, "dotf-allow")) next
      if (length(text) > 100) text = substr(text, 1, 100) "..."
      printf "  %s:%s  [%s]  %s\n", $1, $2, rule[FNR], text
      found = 1
    }
    END { exit found }
  ' "$_tmp/hits" "$_tmp/in"
  _rc=$?
  rm -rf "$_tmp"
  return $_rc
}

# Les hooks git n'ont pas forcément ~/.local/bin dans le PATH.
guard_gitleaks_bin() {
  command -v gitleaks 2>/dev/null && return 0
  [ -x "$HOME/.local/bin/gitleaks" ] && echo "$HOME/.local/bin/gitleaks"
}

_guard_gitleaks() { # staged | all | range <arguments de git log>
  _gl=$(guard_gitleaks_bin) || return 0
  "$_gl" git --help >/dev/null 2>&1 || { log_info "gitleaks trop ancien (< 8.19), ignoré"; return 0; }
  set -- "$@" --no-banner --redact --log-level warn --verbose --no-color
  case $1 in
    staged) shift; "$_gl" git --pre-commit --staged "$@" "$DOTF" ;;
    all) shift; "$_gl" dir "$@" "$DOTF" ;;
    range) _range=$2; shift 2; "$_gl" git --log-opts="$_range" "$@" "$DOTF" ;;
  esac </dev/null
}

# Plages de commits poussés, lues sur l'entrée du hook pre-push.
_guard_prepush_ranges() {
  _zero=$(printf '%040d' 0)
  while read -r _lref _lsha _rref _rsha; do
    case $_lsha in "$_zero" | "") continue ;; esac # suppression de branche
    if [ "$_rsha" = "$_zero" ]; then
      echo "$_lsha --not --remotes"
    else
      echo "$_rsha..$_lsha"
    fi
  done
}

guard_scan() { # staged | all | pre-push
  [ -r "$DOTF_LOCAL/denylist" ] ||
    log_warn "pas de liste noire ($(tilde "$DOTF_LOCAL")/denylist) : seules les règles génériques s'appliquent"
  case $1 in
    staged | all)
      _fail=0
      "_guard_lines_$1" | _guard_match || _fail=1
      _guard_gitleaks "$1" || _fail=1
      return $_fail
      ;;
    pre-push)
      _guard_prepush_ranges | {
        _fail=0
        while read -r _range; do
          # shellcheck disable=SC2086 # « <sha> --not --remotes » : plusieurs arguments
          _guard_lines_range $_range | _guard_match || _fail=1
          _guard_gitleaks range "$_range" || _fail=1
        done
        exit $_fail
      }
      ;;
  esac
}

# --- install / remove / status ---

_guard_denylist_count() {
  if [ -r "$DOTF_LOCAL/denylist" ]; then grep -cvE '^[[:space:]]*(#|$)' "$DOTF_LOCAL/denylist" || true; else echo 0; fi
}

guard_install() {
  repo_is_git || { log_info "pas un dépôt git, ignoré"; return 0; }
  if [ "$(git -C "$DOTF" config --get core.hooksPath)" = .githooks ]; then
    log_info "hooks pre-commit et pre-push déjà actifs"
  else
    git -C "$DOTF" config core.hooksPath .githooks
    log_ok "hooks pre-commit et pre-push activés"
  fi
  [ "$(_guard_denylist_count)" -gt 0 ] || log_warn "liste noire vide : la remplir dans $(tilde "$DOTF_LOCAL")/denylist"
}

guard_remove() {
  repo_is_git || return 0
  if [ "$(git -C "$DOTF" config --get core.hooksPath)" = .githooks ]; then
    git -C "$DOTF" config --unset core.hooksPath
    log_ok "hooks désactivés"
  fi
}

guard_status() {
  if [ "$(git -C "$DOTF" config --get core.hooksPath 2>/dev/null)" = .githooks ]; then
    log_ok "hooks pre-commit et pre-push actifs"
  else
    log_warn "hooks inactifs : relancer « dotf install »"
  fi
  _n=$(_guard_denylist_count)
  if [ "$_n" -gt 0 ]; then
    log_ok "liste noire : $_n motif(s)"
  else
    log_warn "liste noire vide : la remplir dans $(tilde "$DOTF_LOCAL")/denylist"
  fi
  if guard_gitleaks_bin >/dev/null; then
    log_ok "gitleaks utilisé en complément"
  else
    log_info "gitleaks absent : « dotf install » l'installe (module du socle)"
  fi
}
