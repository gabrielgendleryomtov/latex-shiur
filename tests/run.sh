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
# lines; see tests/check.py. Examples (tests/examples) must build. Every
# document must build with no error and no missing character.

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
	for doc in "$repo"/tests/cases/*.tex "$repo"/tests/examples/*.tex; do
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
	id=${id#"$HOME"/}
	id=${id%.tex}
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

mapfile -t list < <(docs "$@")
((${#list[@]})) || { echo "no documents match" >&2; exit 2; }
mkdir -p "$out"
start=$SECONDS
results=$(printf '%s\0' "${list[@]}" | xargs -0 -n1 -P "$(nproc)" bash -c 'one "$1"' _ | sort)
echo "$results" | grep -v '^ok ' || true
passed=$(grep -c '^ok ' <<<"$results")
echo "$passed of ${#list[@]} passed ($((SECONDS - start)) s)"
((passed == ${#list[@]}))
