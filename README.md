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
- A font with Hebrew. FreeSerif comes with TeX Live and is used if nothing better is installed.
- For Tanakh with trop (cantillation marks), a font that places trop well: **Ezra SIL**
  (`sudo apt install fonts-sil-ezra` on Debian/Ubuntu, or from
  [SIL](https://software.sil.org/ezra/)) or **Taamey Frank CLM** (from
  [Culmus](https://culmus.sourceforge.io)). General fonts tend to crowd or misplace trop, and
  the package warns when Tanakh with trop falls back to one.

## Installation

Clone the repository somewhere TeX searches, for example:

```sh
git clone https://github.com/gabrielgendleryomtov/latex-shiur.git "$(kpsewhich -var-value TEXMFHOME)/tex/latex/shiur"
```

## Quick start

```latex
\documentclass[11pt]{article}
\usepackage{shiur}
\setshiurfont{hebrew}{FreeSerif}   % optional: without it, an installed font is chosen

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

Compile it with `xelatex` (twice, for the PDF bookmarks).

## What's in the package

| | |
|---|---|
| `mekor`, `mekor*` | One numbered source; a continuation that takes no new number. One frame each on slides. |
| `mekorlang[subtitle]{language}{title}` | One language of a source. `hebrew`, `mikra` (Tanakh) and `rashi` are Hebrew, set right to left with Hebrew numerals, each in its own font. |
| `\pasuk`, `\pasuk[23]`, `\pasuk[37:18]`, `\perek{38}` | Verse numbers in Tanakh: (19), (23), (37:18), (38:1), or (יט), (כג), (לז יח), (לח א) in Hebrew. A skipped verse gets "..." first; `\pasuk*`/`\perek*` force it. |
| `\tanakh`, `\bavli`, `\mishnah`, `\yerushalmi`, `\rambam`, `\shulchanaruch`, `\tur` (and `\beityosef`, `\darkeimoshe`, `\bach`, `\shakh`, `\taz`, `\magenavraham`, `\mishnahberurah`, `\arukhhashulchan`; `\declaretursefer` adds more), `\sham` | References, from the companion `mareimekomot` package, set in the language around them: `\tanakh{gen}{37:18-20}` gives Genesis 37:18–20 / בראשית ל״ז, י״ח–כ׳; `\shulchanaruch{oh}{605:1}` gives Shulḥan Arukh, Oraḥ Ḥayyim 605:1 / שו״ע או״ח סי׳ תר״ה סע׳ א׳; `\sham` gives ad loc / שם. |
| `\dilug` | Marks text left out with "...", in any language; never doubles up with a verse marker's or a slide break's ellipsis. |
| `\setshiurfont{role}[options]{font}` | Choose the font for `hebrew`, `mikra` or `rashi`, with `fontspec` options. Unset roles get an installed font from a built-in list. |
| `note`, `gnote`, `prenote`, `postnote` | Teacher's notes, printed only with `maggidshiur`. Optional argument: the note's language. Use `gnote` with beamer or `beamerarticle`. |
| `\mekorbreak`, `\mekorbreak*` | Split a source over several slides, with or without an ellipsis at the cut. Handouts ignore it. |
| `\iftranslations{bilingual}{Hebrew-only}` | Text for just one of the two versions. |
| `\makeTitle` | Title, plus the page style with בס״ד in the header. |
| `\attribution{who}{where}{when}` | "who, where, when", leaving out empty parts. |
| `\hdot`, `\Hdot`, `\sectionsymbol`, `boxedtext` | ḥ, Ḥ, §, and text in a box. |

### Fonts

Hebrew has three roles, used as the language of a source or note: `hebrew` for most text,
`mikra` for Tanakh, and `rashi` for Rashi script. Each can have its own font:

```latex
\setshiurfont{hebrew}{Frank Ruehl CLM}
\setshiurfont{mikra}{Taamey Frank CLM}
\setshiurfont{rashi}{Noto Rashi Hebrew}
```

See [`doc/shiur-fonts.pdf`](doc/shiur-fonts.pdf) for a sample sheet using all three.
A role left unset uses the first installed font from a list (for `mikra`: Taamey Frank CLM,
Taamey David CLM, Ezra SIL, SBL Hebrew, Keter YG), then the `hebrew` font, and finally
FreeSerif. Documents that define `\hebrewfont` themselves keep it.

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

## Wishlist

Ideas for later versions, not yet planned in detail:

- **Hebrew and English side by side**, in two columns, as an alternative to one after the other.
- **Long sources that flow onto the next slide by themselves**, sharing each slide's space between
  Hebrew and English the way an article paginates, instead of manual `\mekorbreak`s.
- **A written-up prose version** of a shiur, made from the same body as its sheet and slides.

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
