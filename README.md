# shiur

A LaTeX package for Jewish source sheets (*dappei mekorot*): numbered sources in Hebrew
with English translations, plus notes for the person teaching. From one file of content it
makes:

- a handout for participants (*talmid*) and one with the teacher's notes (*maggid shiur*);
- a bilingual handout and a Hebrew-only one;
- a large-print handout;
- beamer slides, with long sources split over several slides.

Each version is a small wrapper file around the shared content, so a correction made once
shows up everywhere.

The manual, [`doc/shiur-doc.pdf`](doc/shiur-doc.pdf), covers everything below in more detail.

## Requirements

- XeLaTeX, with a recent TeX distribution (LaTeX 2022-06 or later; developed on TeX Live 2025).
- A font with Hebrew, such as FreeSerif (in TeX Live as `gnu-freefont`).

## Installation

Clone the repository somewhere TeX searches, for example:

```sh
git clone <repository-url> "$(kpsewhich -var-value TEXMFHOME)/tex/latex/shiur"
```

## Quick start

```latex
\documentclass[11pt]{article}
\usepackage{shiur}
\newfontfamily{\hebrewfont}{FreeSerif}

\title{Wheat from the clouds}
\author{A. Teacher}
\date{}

\begin{document}
\makeTitle

\begin{mekor}
\begin{mekorlang}{hebrew}{בבלי מנחות ס״ט ע״ב}
בעי ר׳ זירא: חיטין שירדו בעבים מהו?
\end{mekorlang}
\begin{mekorlang}{english}{B. Mena\hdot ot 69b}
R. Zeira asked: ``if wheat descended in clouds, what is the law?''
\end{mekorlang}
\end{mekor}

% printed only with \usepackage[maggidshiur]{shiur}
\begin{note}
Why does R. Zeira ask about wheat rather than any other food?
\end{note}

\end{document}
```

Compile it with `xelatex` (twice, for the PDF bookmarks). In beamer, set the Hebrew font with
`\newfontfamily{\hebrewfontsf}{...}` instead.

## What's in the package

| | |
|---|---|
| `mekor`, `mekor*` | One numbered source; a continuation that takes no new number. One frame each on slides. |
| `mekorlang[subtitle]{language}{title}` | One language of a source. `hebrew` is set right to left with Hebrew numerals. |
| `note`, `gnote`, `prenote`, `postnote` | Teacher's notes, printed only with `maggidshiur`. Optional argument: the note's language. Use `gnote` with beamer or `beamerarticle`. |
| `\mekorbreak`, `\mekorbreak*` | Split a source over several slides, with or without an ellipsis at the cut. Handouts ignore it. |
| `\iftranslations{bilingual}{Hebrew-only}` | Text for just one of the two versions. |
| `\makeTitle` | Title, plus the page style with בס״ד in the header. |
| `\attribution{who}{where}{when}` | "who, where, when", leaving out empty parts. |
| `\hdot`, `\Hdot`, `\sectionsymbol`, `boxed` | ḥ, Ḥ, §, and a boxed paragraph. |

### Options

| Option | Effect |
|---|---|
| `talmid` (default) | Leave out the notes. |
| `maggidshiur` | Print the notes. |
| `translations=false` | Leave out English translations of Hebrew sources. Sources written in English stay. |
| `accessible`, `accessible=20pt` | Large-print handout: 18pt (or the given size), unjustified. Slides are unchanged. |

### One body, several versions

Put the content in a body file and give each version a wrapper:

```latex
% sheet_hebrew.tex
\PassOptionsToPackage{translations=false}{shiur}
\input{sheet_body}
```

To make slides from the same body, the handout wrapper loads `beamerarticle` before `shiur`,
and the slide wrapper uses `\documentclass{beamer}`. The body can then use
`\mode<presentation>{...}` and `\mode<article>{...}` for material that belongs to only one
of them. The manual has a complete example.

`shiurbeamer.sty` is kept so that older documents still compile; it just loads `shiur`.

## Tests

`tests/regress.sh baseline`, then `tests/regress.sh check` after a change, compiles the
documents listed in `tests/docs.txt` against the committed and the working version of the
package, and compares the PDFs page by page as text and images. It needs `pdftotext`,
`pdftoppm` and ImageMagick's `compare`.

## Licence

Copyright 2023–2026 Gabriel Gendler Yom-Tov. Distributed under the
[LaTeX Project Public License](LICENSE), version 1.3c or later.

Contact: shiurtex@thm.mozmail.com

Much of version 2 was developed with [Claude Code](https://claude.com/claude-code).
