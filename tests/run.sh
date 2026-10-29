#!/usr/bin/env bash
# Tests: compile the test documents against the working tree, in parallel, and
# check what their PDFs say.
#
#   tests/run.sh             every test case and example
#   tests/run.sh WORD...     only those whose file names contain a WORD
#   tests/run.sh --mine      the documents listed in tests/mine.local (absolute
#                            paths, gitignored), checking only that they build
#
# Test cases (tests/cases/*.tex) state what their PDFs must show, in comment
# lines; see tests/check.py. Examples (tests/examples), and every version of a
# shiur made by scripts/newshiur, must build. Every document must build with no
# error and no missing character. The newshiur versions are compiled by
# scripts/buildshiur, which must also report an error in a broken copy of them.

set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
# outside TEXMFHOME, so that TeX never finds files from here in normal use
out=${SHIUR_TEST_OUT:-${XDG_CACHE_HOME:-$HOME/.cache}/shiur-tests}

docs() {
	if [[ ${1:-} = --mine ]]; then
		[[ -f $repo/tests/mine.local ]] || { echo "no tests/mine.local" >&2; exit 2; }
		grep -v -e '^\s*#' -e '^\s*$' "$repo/tests/mine.local"
		return
	fi
	local doc word
	# a fresh shiur from the starter script, with every version
	rm -rf "$out/starter"
	mkdir -p "$out/starter"
	(cd "$out/starter" && "$repo/scripts/newshiur" --hebrew-only --large-print --font FreeSerif \
		--author "A. Teacher" starter >/dev/null)
	for doc in "$repo"/tests/cases/*.tex "$repo"/tests/examples/*.tex "$out"/starter/starter/*.tex; do
		grep -q '\\documentclass' "$doc" || continue  # bodies are \input by others
		if (($#)); then
			for word; do [[ $(basename "$doc") = *"$word"* ]] && echo "$doc" && break; done
		else
			echo "$doc"
		fi
	done
}

# one DOC: compile it once (from its own directory, for relative paths) and check it
one() {
	local doc=$1 id dir
	id=${doc#"$repo"/tests/}
	id=${id#"$out"/}
	id=${id#"$HOME"/}
	id=${id%.tex}
	if [[ $doc = "$out"/starter/* ]]; then  # compiled already, by buildshiur
		python3 -I "$repo/tests/check.py" "$id" "$doc" "${doc%.tex}.pdf" "${doc%.tex}.log"
		return
	fi
	dir=$out/${id//\//__}
	rm -rf "$dir"
	mkdir -p "$dir"
	(cd "$(dirname "$doc")" &&
		TEXINPUTS="$repo//:" timeout 300 xelatex -interaction=nonstopmode -halt-on-error \
			-output-directory="$dir" -jobname=doc "$(basename "$doc")" >/dev/null 2>&1)
	python3 -I "$repo/tests/check.py" "$id" "$doc" "$dir/doc.pdf" "$dir/doc.log"
}
export -f one
export repo out

# buildshiur: compile the starter, and a copy of it with an unknown command in its body; print a
# result line for each
buildshiur() {
	local status=0 report wrappers
	report=$(TEXINPUTS="$repo//:" "$repo/scripts/buildshiur" "$out/starter/starter") || status=$?
	if ((status)); then
		echo "FAIL buildshiur: exit $status"$'\n'"$report"
	else
		echo "ok scripts/buildshiur"
	fi
	rm -rf "$out/starter/broken"
	cp -r "$out/starter/starter" "$out/starter/broken"
	sed -i 's/^\\maketitle$/&\n\\nosuchcommand/' "$out/starter/broken/starter_body.tex"
	status=0
	report=$(TEXINPUTS="$repo//:" "$repo/scripts/buildshiur" "$out/starter/broken") || status=$?
	wrappers=$(grep -l 'input{starter_body}' "$out"/starter/starter/*.tex | wc -l)
	if ((status == 1)) && (($(grep -c '^FAIL .*starter_body.tex:[0-9]*: Undefined control sequence. \\nosuchcommand' <<<"$report") == wrappers)); then
		echo "ok scripts/buildshiur, errors"
	else
		echo "FAIL buildshiur, errors: exit $status"$'\n'"$report"
	fi
}

mapfile -t list < <(docs "$@")
((${#list[@]})) || { echo "no documents match" >&2; exit 2; }
mkdir -p "$out"
start=$SECONDS
others=() starters=()
for doc in "${list[@]}"; do
	if [[ $doc = "$out"/starter/* ]]; then starters+=("$doc"); else others+=("$doc"); fi
done
# buildshiur compiles the starter alongside the other documents; its versions are checked after
if ((${#starters[@]})); then
	buildshiur >"$out/buildshiur.txt" &
	builder=$!
	list+=(buildshiur buildshiur)  # its two result lines
fi
results=
((${#others[@]})) &&
	results=$(printf '%s\0' "${others[@]}" | xargs -0 -n1 -P "$(nproc)" bash -c 'one "$1"' _)
if ((${#starters[@]})); then
	wait "$builder"
	results+=$'\n'$(cat "$out/buildshiur.txt")
	results+=$'\n'$(printf '%s\0' "${starters[@]}" | xargs -0 -n1 -P "$(nproc)" bash -c 'one "$1"' _)
fi
results=$(sort <<<"$results" | sed '/^$/d')
echo "$results" | grep -v '^ok ' || true
passed=$(grep -c '^ok ' <<<"$results")
echo "$passed of ${#list[@]} passed ($((SECONDS - start)) s)"
((passed == ${#list[@]}))
