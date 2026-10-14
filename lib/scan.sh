# shellcheck shell=sh
# Garde-fou anti-fuite : cherche les secrets et les données personnelles dans ce qui va être commité ou poussé.
#
# Deux sources de règles :
#   - les règles génériques ci-dessous (clés privées, jetons, mots de passe…), publiques ;
#   - la liste noire de la machine, $DOTF_LOCAL/denylist, jamais versionnée (noms d'hôtes, domaines, identifiants…).
# Pour laisser passer une ligne signalée à tort, y ajouter le commentaire « dotf-allow ».

# Règles génériques : nom<TAB>options<TAB>regex (ERE pour grep -E).
# Options : i = insensible à la casse, w = mot entier, - = aucune.
_scan_builtin_rules() {
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
}

# Liste noire locale : un motif ERE par ligne, # pour commenter ; insensible à la casse, en mot entier.
_scan_rules() {
  _scan_builtin_rules
  if [ -r "$DOTF_LOCAL/denylist" ]; then
    awk '{ sub(/[ \t]*#.*/, ""); gsub(/^[ \t]+|[ \t]+$/, ""); if ($0 != "") print "liste-noire\tiw\t" $0 }' "$DOTF_LOCAL/denylist"
  fi
}

# --- Extraction des lignes à vérifier, au format fichier<TAB>ligne<TAB>contenu ---

# Lignes ajoutées d'un diff unifié (-U0) lu sur l'entrée standard.
# Les lignes « @commit <sha> » produites par scan_range préfixent les noms de fichiers.
_scan_parse_diff() {
  awk '
    /^@commit / { c = $2 ":"; next }
    /^\+\+\+ / { f = substr($0, 5); sub(/^b\//, "", f); next }
    /^@@/ { match($0, /\+[0-9]+/); n = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
    /^\+/ { printf "%s%s\t%d\t%s\n", c, f, n, substr($0, 2); n++ }
  '
}

_scan_lines_staged() {
  git -C "$DOTF" diff --cached -U0 --no-color --no-ext-diff --diff-filter=ACMR | _scan_parse_diff
}

# $@ : arguments de git log (ex. A..B, ou <sha> --not --remotes)
_scan_lines_range() {
  git -C "$DOTF" log -p -U0 --no-color --no-ext-diff -m --first-parent --format='@commit %h' "$@" | _scan_parse_diff
}

# Tous les fichiers texte suivis ou nouveaux (hors .gitignore).
_scan_lines_all() {
  git -C "$DOTF" ls-files -z --cached --others --exclude-standard | (
    cd "$DOTF" && xargs -0 grep -I -l -e '' -- 2>/dev/null
  ) | while IFS= read -r _f; do
    awk -v f="$_f" '{ printf "%s\t%d\t%s\n", f, FNR, $0 }' "$DOTF/$_f"
  done
}

# --- Analyse -------------------------------------------------------------------

# Lit les lignes sur l'entrée standard, affiche les trouvailles ; code 1 si au moins une.
# La recherche passe par grep -E : mawk (awk par défaut de Debian) gère mal les répétitions {n,}.
_scan_match() {
  _tmp=$(mktemp -d)
  cat >"$_tmp/in"
  cut -f3- "$_tmp/in" >"$_tmp/text"
  _scan_rules >"$_tmp/rules"
  : >"$_tmp/hits"
  while IFS="$TAB" read -r _name _opts _re; do
    [ -n "$_re" ] || continue
    set --
    case $_opts in *i*) set -- "$@" -i ;; esac
    case $_opts in *w*) set -- "$@" -w ;; esac
    grep -nE "$@" -e "$_re" "$_tmp/text" 2>/dev/null | cut -d: -f1 | sed "s/\$/$TAB$_name/" >>"$_tmp/hits"
  done <"$_tmp/rules"
  # Une seule règle par ligne (la première), lignes « dotf-allow » ignorées.
  awk -F '\t' '
    NR == FNR { if (!($1 in rule)) rule[$1] = $2; next }
    (FNR in rule) {
      text = $0; sub(/^[^\t]*\t[^\t]*\t/, "", text)
      if (index(text, "dotf-allow")) next
      if (length(text) > 100) text = substr(text, 1, 100) "..."
      printf "  %s:%s  [%s]  %s\n", $1, $2, rule[FNR], text
      found = 1
    }
    END { exit found ? 1 : 0 }
  ' "$_tmp/hits" "$_tmp/in"
  _rc=$?
  rm -rf "$_tmp"
  return $_rc
}

# Chemin de gitleaks : dans le PATH, sinon celui du module (les hooks git n'ont pas forcément ~/.local/bin).
scan_gitleaks_bin() {
  command -v gitleaks 2>/dev/null && return 0
  [ -x "$HOME/.local/bin/gitleaks" ] && printf '%s\n' "$HOME/.local/bin/gitleaks"
}

# gitleaks (facultatif, version >= 8.19) : complète les règles génériques.
_scan_gitleaks() {
  _gl=$(scan_gitleaks_bin) || return 0
  "$_gl" git --help >/dev/null 2>&1 || { log_info "gitleaks trop ancien (< 8.19), ignoré"; return 0; }
  case $1 in
    staged) "$_gl" git --pre-commit --staged --no-banner --redact --log-level warn --verbose --no-color "$DOTF" ;;
    range) shift; "$_gl" git --log-opts="$*" --no-banner --redact --log-level warn --verbose --no-color "$DOTF" ;;
    all) "$_gl" dir --no-banner --redact --log-level warn --verbose --no-color "$DOTF" ;;
  esac
}

# Commits qu'un push s'apprête à envoyer, d'après l'entrée standard du hook pre-push.
_scan_prepush_ranges() {
  _zero=$(printf '%040d' 0)
  while read -r _lref _lsha _rref _rsha; do
    case $_lsha in "$_zero" | "") continue ;; esac # suppression de branche
    if [ "$_rsha" = "$_zero" ]; then
      printf '%s --not --remotes\n' "$_lsha"
    else
      printf '%s..%s\n' "$_rsha" "$_lsha"
    fi
  done
}

# scan_run <staged|all|pre-push|range ARGS...>
scan_run() {
  _mode=$1
  shift
  if [ ! -r "$DOTF_LOCAL/denylist" ]; then
    log_warn "pas de liste noire ($(tilde "$DOTF_LOCAL")/denylist) : seules les règles génériques s'appliquent"
  fi
  _fail=0
  case $_mode in
    staged)
      _scan_lines_staged | _scan_match || _fail=1
      _scan_gitleaks staged || _fail=1
      ;;
    all)
      _scan_lines_all | _scan_match || _fail=1
      _scan_gitleaks all || _fail=1
      ;;
    range)
      _scan_lines_range "$@" | _scan_match || _fail=1
      _scan_gitleaks range "$@" || _fail=1
      ;;
    pre-push)
      _ranges=$(_scan_prepush_ranges)
      while read -r _range; do
        [ -n "$_range" ] || continue
        # shellcheck disable=SC2086 # « <sha> --not --remotes » doit être découpé
        _scan_lines_range $_range | _scan_match || _fail=1
        # shellcheck disable=SC2086
        _scan_gitleaks range $_range || _fail=1
      done <<EOF
$_ranges
EOF
      ;;
    *) die "scan : mode inconnu « $_mode »" ;;
  esac
  return $_fail
}
