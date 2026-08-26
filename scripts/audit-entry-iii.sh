#!/usr/bin/env bash
# Additive certification gate for the entry-point (iii) development.
#
# Pins are discovered from their imports rather than maintained in a second
# hand-written list.  This keeps a new EntryIII module from silently escaping
# statement and coverage checks.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.elan/bin:$PATH"

fail=0
pin_files=(gate/entry-iii-*-pins.lean)
if [ ${#pin_files[@]} -eq 0 ] || [ ! -f "${pin_files[0]}" ]; then
  echo "FAIL  no entry-iii pin files found"
  exit 1
fi

check_pin() {
  local pin="$1" baseline now label
  baseline="${pin%-pins.lean}-baseline.txt"
  label="${pin#gate/entry-iii-}"
  label="${label%-pins.lean}"
  if [ ! -f "$baseline" ]; then
    echo "FAIL  $label -- missing baseline $baseline"
    fail=1
    return
  fi
  now=$(lake env lean "$pin" 2>&1)
  if [ $? -ne 0 ]; then
    echo "FAIL  $label pin file does not elaborate"
    printf '%s\n' "$now" | head -30
    fail=1
    return
  fi
  if diff -u "$baseline" <(printf '%s\n' "$now"); then
    echo "ok    $label statement pins"
  else
    echo "FAIL  $label pinned surface changed"
    fail=1
  fi
}

pin_for_module() {
  local module="$1" matches count
  matches=$(grep -l -x -F "import $module" "${pin_files[@]}" 2>/dev/null || true)
  count=$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$count" -ne 1 ]; then
    echo "FAIL  $module -- expected exactly one matching pin file, found $count" >&2
    [ -z "$matches" ] || printf '%s\n' "$matches" >&2
    fail=1
    return 1
  fi
  printf '%s\n' "$matches"
}

check_source_coverage() {
  local source module pin entry kind declaration escaped qualified candidate
  local missing=0 declared=0 certified
  for source in MatchingLogic/EntryIII/*.lean; do
    module="${source%.lean}"
    module="${module//\//.}"
    # `fail=1` inside pin_for_module dies with the command substitution's
    # SUBSHELL. Round ten: the gate printed three FAIL lines and exited 0, and
    # the three modules holding the new separation results were dropped from the
    # coverage scan silently -- `missing` stayed 0 and the count line read `ok`.
    # Any module could be put outside this gate by deleting its pin pair. The
    # caller must set the flag.
    if ! pin=$(pin_for_module "$module"); then fail=1; continue; fi
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      kind="${entry%%|*}"
      declaration="${entry#*|}"
      declared=$((declared + 1))
      # EntryIII declaration names are Lean identifiers plus dots; escaping
      # dots is sufficient for the boundary-aware grep below.
      escaped=$(printf '%s' "$declaration" | sed 's/\./\\./g')
      if ! grep -E -q "(^|[ .@])${escaped}([ .]|$)" "$pin"; then
        echo "FAIL  $source declares '$declaration' but $pin does not pin it"
        missing=$((missing + 1))
        continue
      fi
      if [ "$kind" = theorem ]; then
        qualified=$(awk -v suffix=".$declaration" '
          $1 == "#check" {
            name = $2
            sub(/^@/, "", name)
            if (length(name) >= length(suffix) &&
                substr(name, length(name) - length(suffix) + 1) == suffix)
              print name
          }
          $1 == "#print" && $2 == "axioms" {
            name = $3
            if (length(name) >= length(suffix) &&
                substr(name, length(name) - length(suffix) + 1) == suffix)
              print name
          }
        ' "$pin" | sort -u)
        certified=0
        while IFS= read -r candidate; do
          [ -z "$candidate" ] && continue
          if grep -F -x -q "$candidate" gate/entry-iii-certified.txt; then
            certified=1
            break
          fi
        done <<< "$qualified"
        if [ "$certified" -ne 1 ]; then
          echo "FAIL  $source theorem '$declaration' is pinned but not certified"
          missing=$((missing + 1))
        fi
      fi
    done < <(
      awk '
        /^[[:space:]]*((protected|noncomputable|private)[[:space:]]+)*(theorem|def|abbrev|structure|inductive)[[:space:]]+/ {
          line = $0
          if (line ~ /(^|[[:space:]])private[[:space:]]/) next
          sub(/^[[:space:]]*/, "", line)
          while (line ~ /^(protected|noncomputable)[[:space:]]+/)
            sub(/^(protected|noncomputable)[[:space:]]+/, "", line)
          kind = line
          sub(/[[:space:]].*$/, "", kind)
          sub(/^(theorem|def|abbrev|structure|inductive)[[:space:]]+/, "", line)
          split(line, fields, /[[:space:]:({]/)
          print kind "|" fields[1]
        }
      ' "$source"
    )
  done
  if [ "$declared" -eq 0 ]; then
    echo "FAIL  EntryIII coverage scan found no public declarations"
    fail=1
  elif [ "$missing" -eq 0 ]; then
    echo "ok    $declared EntryIII public declarations pinned"
  else
    echo "FAIL  $missing of $declared EntryIII public declarations are unpinned"
    fail=1
  fi
}

# Normalize one complete `#print axioms` stanza without discarding continuation
# lines.  This is the critical distinction from the original first-line-only
# parser, which could miss a forbidden token after pretty-printer wrapping.
normalize_axiom_stanza() {
  awk '{
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    if (NR > 1) printf " "
    printf "%s", $0
  } END { print "" }'
}

# Return 0 for an allowed kernel verdict, 1 for a disallowed axiom token, and
# 2 for malformed normalized output.
parse_axiom_verdict() {
  local name="$1" line="$2" prefix payload token
  AXIOM_BAD=""
  prefix="'$name' "
  case "$line" in
    "${prefix}does not depend on any axioms") return 0 ;;
    "${prefix}depends on axioms: ["*"]")
      payload="${line#"${prefix}depends on axioms: ["}"
      payload="${payload%]}"
      ;;
    *) return 2 ;;
  esac
  [ -n "$payload" ] || return 2
  case "$payload" in *'['*|*']'*|*'  '*) return 2 ;; esac
  while IFS= read -r token; do
    token=$(printf '%s' "$token" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$token" in
      propext|Classical.choice|Quot.sound) ;;
      '') return 2 ;;
      *) AXIOM_BAD="$token"; return 1 ;;
    esac
  done < <(printf '%s\n' "$payload" | tr ',' '\n')
  return 0
}

parser_self_test() {
  local status verdict
  parse_axiom_verdict Synthetic.allowed \
    "'Synthetic.allowed' depends on axioms: [propext, Classical.choice, Quot.sound]"
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "FAIL  axiom parser self-test rejected an allowed list"
    fail=1
  fi
  verdict=$(printf '%s\n' \
    "'Synthetic.disallowed' depends on axioms: [propext," \
    " Synthetic.bad]" | normalize_axiom_stanza)
  parse_axiom_verdict Synthetic.disallowed "$verdict"
  status=$?
  if [ "$status" -ne 1 ] || [ "$AXIOM_BAD" != "Synthetic.bad" ]; then
    echo "FAIL  axiom parser self-test did not detect a synthetic disallowed token"
    fail=1
  fi
  verdict=$(printf '%s\n' \
    "'Synthetic.wrapped' depends on axioms: [propext," \
    " Classical.choice," \
    " Quot.sound]" | normalize_axiom_stanza)
  parse_axiom_verdict Synthetic.wrapped "$verdict"
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "FAIL  axiom parser self-test rejected a wrapped allowed verdict"
    fail=1
  fi
  [ "$fail" -ne 0 ] || echo "ok    axiom verdict parser self-test"
}

modules=()
for source in MatchingLogic/EntryIII/*.lean; do
  module="${source%.lean}"
  modules+=("${module//\//.}")
done
BUILD=$(lake build "${modules[@]}" 2>&1)
if [ $? -ne 0 ]; then
  echo "FAIL  entry-iii modules do not build"
  printf '%s\n' "$BUILD" | tail -40
  exit 1
fi
echo "ok    ${#modules[@]} EntryIII modules build"

for pin in "${pin_files[@]}"; do
  check_pin "$pin"
done
check_source_coverage

# Plain grep, not rg: the old `if rg ...; then` treated exit 127 (rg not
# installed) the same as "no matches" and printed ok without scanning anything.
# grep is everywhere; exit 0 = matches, 1 = no matches, >=2 = error. Fail
# closed on anything but a clean no-match.
GREP_OUT=$(grep -rEn --include='*.lean' '(^|[^A-Za-z])(sorry|axiom|native_decide)([^A-Za-z_]|$)' MatchingLogic/EntryIII 2>&1)
GREP_STATUS=$?
if [ "$GREP_STATUS" -eq 1 ]; then
  echo "ok    no sorry, axiom, or native_decide in entry-iii sources"
elif [ "$GREP_STATUS" -eq 0 ]; then
  printf '%s\n' "$GREP_OUT"
  echo "FAIL  forbidden declaration or proof shortcut in entry-iii sources"
  fail=1
else
  echo "FAIL  source scan errored (exit $GREP_STATUS): $GREP_OUT"
  fail=1
fi

parser_self_test

AUDIT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ml-entry-iii-audit.XXXXXX") || {
  echo "FAIL  could not create temporary audit directory"
  exit 1
}
AUDIT="$AUDIT_DIR/axioms.lean"
trap 'rm -rf "$AUDIT_DIR"' EXIT
for source in MatchingLogic/EntryIII/*.lean; do
  module="${source%.lean}"
  printf 'import %s\n' "${module//\//.}" >> "$AUDIT"
done
names=()
while IFS= read -r name; do
  case "$name" in ''|'#'*) continue ;; esac
  names+=("$name")
  printf '#print axioms %s\n' "$name" >> "$AUDIT"
done < gate/entry-iii-certified.txt

OUT=$(lake env lean "$AUDIT" 2>&1)
if [ $? -ne 0 ]; then
  echo "FAIL  entry-iii axiom audit does not elaborate"
  printf '%s\n' "$OUT"
  exit 1
fi

for name in "${names[@]}"; do
  verdict_count=$(printf '%s\n' "$OUT" | grep -F -c "'$name' " || true)
  if [ "$verdict_count" -ne 1 ]; then
    echo "FAIL  $name -- expected one axiom verdict, found $verdict_count"
    fail=1
    continue
  fi
  stanza=$(printf '%s\n' "$OUT" | awk -v target="$name" '
    BEGIN { prefix = sprintf("\047%s\047 ", target) }
    index($0, prefix) == 1 { capture = 1 }
    capture {
      if (printed && substr($0, 1, 1) == "\047") exit
      print
      printed = 1
    }
  ')
  verdict=$(printf '%s\n' "$stanza" | normalize_axiom_stanza)
  parse_axiom_verdict "$name" "$verdict"
  status=$?
  case "$status" in
    0) echo "ok    $name" ;;
    1) echo "FAIL  $name -- disallowed axiom: $AXIOM_BAD"; fail=1 ;;
    *) echo "FAIL  $name -- malformed axiom verdict: $verdict"; fail=1 ;;
  esac
done

# See scripts/audit.sh: `printf | grep -q` under pipefail can fail OPEN.
if case "$OUT" in *sorryAx*) true ;; *) false ;; esac; then
  echo "FAIL  sorryAx is reachable from an entry-iii theorem"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "== ENTRY III GATE PASS =="
else
  echo "== ENTRY III GATE FAIL =="
fi
exit "$fail"
