#!/usr/bin/env bash
# Visual regression test: build documents against a reference version of the
# package and against the working tree, then compare the PDFs page by page.
#
#   tests/regress.sh baseline [REF]   build against git REF (default HEAD)
#   tests/regress.sh check            build against the working tree and compare
#
# Documents come from tests/docs.txt (committed examples, paths relative to the
# repo root) and tests/docs.local (optional, gitignored, absolute paths to
# private documents). Each document is compiled from its own directory so that
# relative paths to images and fonts keep working.

set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
# Output must live outside TEXMFHOME, or TeX would find the baseline copy of the
# package in normal use.
out=${SHIUR_TEST_OUT:-${XDG_CACHE_HOME:-$HOME/.cache}/shiur-tests}

docs() {
	local list
	for list in "$repo/tests/docs.txt" "$repo/tests/docs.local"; do
		[[ -f $list ]] || continue
		grep -v -e '^\s*#' -e '^\s*$' "$list" | while read -r doc; do
			[[ $doc = /* ]] || doc=$repo/$doc
			echo "$doc"
		done
	done
}

# A short unique name for a document, from its path.
docid() {
	local rel=${1#"$repo"/}
	rel=${rel#"$HOME"/}
	rel=${rel%.tex}
	echo "${rel//\//__}"
}

# build SRCDIR OUTDIR: compile every document with SRCDIR first on TEXINPUTS.
build() {
	local src=$1 dest=$2 doc id dir status=0
	rm -rf "$dest"
	mkdir -p "$dest"
	while read -r doc; do
		id=$(docid "$doc")
		dir=$dest/$id
		mkdir -p "$dir"
		for pass in 1 2; do
			(cd "$(dirname "$doc")" &&
				TEXINPUTS="$src//:" xelatex -interaction=nonstopmode -halt-on-error \
					-output-directory="$dir" -jobname=doc "$(basename "$doc")" >/dev/null 2>&1)
		done
		if [[ -f $dir/doc.pdf ]] && ! grep -q '^! ' "$dir/doc.log"; then
			echo "built   $id"
		else
			echo "FAILED  $id (see $dir/doc.log)"
			status=1
		fi
	done < <(docs)
	return $status
}

# compare ID: diff text and rasterised pages of baseline vs current.
compare_doc() {
	local id=$1 b=$out/baseline/$1 c=$out/current/$1 d=$out/diff/$1
	local bp cp page differ=()
	if [[ ! -f $b/doc.pdf || ! -f $c/doc.pdf ]]; then
		echo "MISSING $id"
		return 1
	fi
	mkdir -p "$d"
	bp=$(pdfinfo "$b/doc.pdf" | awk '/^Pages:/ {print $2}')
	cp=$(pdfinfo "$c/doc.pdf" | awk '/^Pages:/ {print $2}')
	pdftotext -layout "$b/doc.pdf" "$d/baseline.txt"
	pdftotext -layout "$c/doc.pdf" "$d/current.txt"
	diff -u "$d/baseline.txt" "$d/current.txt" >"$d/text.diff"
	pdftoppm -r 60 -png "$b/doc.pdf" "$d/b"
	pdftoppm -r 60 -png "$c/doc.pdf" "$d/c"
	for page in "$d"/b-*.png; do
		page=${page#"$d"/b-}
		if [[ ! -f $d/c-$page ]] ||
			[[ $(compare -metric AE "$d/b-$page" "$d/c-$page" "$d/diff-$page" 2>&1 >/dev/null | cut -d' ' -f1) != 0 ]]; then
			differ+=("${page%.png}")
		else
			rm -f "$d/diff-$page"
		fi
	done
	rm -f "$d"/b-*.png "$d"/c-*.png
	if [[ $bp != "$cp" || ${#differ[@]} -gt 0 ]]; then
		echo "DIFFERS $id: pages $bp -> $cp; changed pages: ${differ[*]:-none} (see $d)"
		return 1
	fi
	rm -rf "$d"
	echo "same    $id"
}

case ${1:-} in
baseline)
	ref=${2:-HEAD}
	src=$out/ref-src
	rm -rf "$src"
	mkdir -p "$src"
	git -C "$repo" archive "$ref" -- . ':!tests' | tar -x -C "$src"
	echo "baseline: $(git -C "$repo" rev-parse --short "$ref")"
	build "$src" "$out/baseline"
	;;
check)
	[[ -d $out/baseline ]] || { echo "run '$0 baseline' first" >&2; exit 2; }
	build "$repo" "$out/current"
	status=$?
	rm -rf "$out/diff"
	while read -r doc; do
		compare_doc "$(docid "$doc")" || status=1
	done < <(docs)
	exit $status
	;;
*)
	sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
	exit 2
	;;
esac
