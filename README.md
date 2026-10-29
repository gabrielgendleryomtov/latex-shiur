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
\maketitle

\begin{mekor}
\begin{mekorlang}{hebrew}{בבלי מנחות ס״ט ע״ב}
בעי ר׳ זירא: חיטין שירדו בעבים מהו?
\end{mekorlang}
\begin{mekorlang}{english}{B. Mena\hdot ot 69b}
R. Zeira asked: ``if wheat descended in clouds, what is the law?''
\end{mekorlang}
\end{mekor}

% printed only with \usepackage[maggidshiur]{shiur}
\begin{hearah}
Why does R. Zeira ask about wheat rather than any other food?
\end{hearah}

\end{document}
```

Compile it with `xelatex` (twice, for the PDF bookmarks).

## What's in the package

| | |
|---|---|
| `mekor`, `mekor*` | One numbered source; a continuation under the same number. One frame each on slides. |
| `mekorlang[subtitle]{language}{title}` | One language of a source. `hebrew`, `mikra` (Tanakh) and `rashi` are Hebrew, set right to left with Hebrew numerals, each in its own font. |
| `\pasuk`, `\pasuk[23]`, `\pasuk[37:18]`, `\perek{38}` | Verse numbers in Tanakh: (19), (23), (37:18), (38:1), or (יט), (כג), (לז יח), (לח א) in Hebrew. A skipped verse gets "..." first; `\pasuk*`/`\perek*` force it. |
| `\tanach` (with commentaries: `\tanach[rashi]{gen}{18:7}`; `\declarecommentary` adds more), `\bavli`, `\mishnah`, `\yerushalmi`, `\rambam`, `\shulchanaruch`, `\tur` (and `\beityosef`, `\darkeimoshe`, `\bach`, `\shach`, `\taz`, `\magenavraham`, `\mishnahberurah`, `\aruchhashulchan`; `\declaretursefer` adds more), `\sham` | References, from the companion `mareimekomot` package, set in the language around them: `\tanach{gen}{37:18-20}` gives Genesis 37:18–20 / בראשית ל״ז, י״ח–כ׳; `\shulchanaruch{oh}{605:1}` gives Shulḥan Arukh, Oraḥ Ḥayyim 605:1 / שו״ע או״ח סי׳ תר״ה סע׳ א׳; `\sham` gives ad loc / שם. Keys and command names take any usual transliteration: `menachot`, `menakhot` and `menahot` are the same, as are `\tanach` and `\tanakh`. The English printed uses ḥ for ח and kh for כ. |
| `\dilug` | Marks text left out with "...", in any language; never doubles up with a verse marker's or a slide break's ellipsis. |
| `\setshiurfont{role}[options]{font}` | Choose the font for `hebrew`, `mikra` or `rashi`, with `fontspec` options. Unset roles get an installed font from a built-in list. |
| `hearah` | A note for the maggid shiur (הערה), printed only with `maggidshiur`. Optional argument: its language. Inside a split source, one before the text goes on the first slide and one after it on the last. |
| `\mekorbreak`, `\mekorbreak*` | Split a source over several slides, with or without an ellipsis at the cut. Handouts ignore it. |
| `\iftranslations{bilingual}{Hebrew-only}` | Text for just one of the two versions. |
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

### Starting a new shiur

`scripts/newshiur NAME` starts a new shiur this way: a folder with `NAME_body.tex` and wrappers
for the participants' handout, the presenter's notes and the slides, plus, with
`--hebrew-only` and `--large-print`, those versions too. The title, author and Hebrew font go
at the top of the body, before `\begin{document}`, so they are set once for every version.
`scripts/newshiur --help` lists its options.

`scripts/buildshiur [FOLDER]` then compiles every version at once, each as many times as it
needs, and prints `ok` or the first error, with its file and line, for each. `--clean` deletes
the auxiliary files afterwards. Both scripts run on Linux and macOS, and on Windows in Git Bash
or WSL.

```sh
scripts/newshiur --title "Wheat from the clouds" --author "A. Teacher" wheat
scripts/buildshiur wheat
```

To avoid typing your name and font every time, set them as environment variables, which the
script uses as its defaults. Add these lines to your shell's startup file (`~/.bashrc` for
bash, `~/.zshrc` for zsh, the default on macOS), then open a new terminal:

```sh
export SHIUR_AUTHOR="A. Teacher"
export SHIUR_HEBREW_FONT="Taamey Frank CLM"
```

To run them as plain `newshiur` and `buildshiur` from anywhere, link them into a folder on your
`PATH`, for example:

```sh
for s in newshiur buildshiur; do
	ln -s "$(kpsewhich -var-value TEXMFHOME)/tex/latex/shiur/scripts/$s" ~/.local/bin/$s
done
```

## Wishlist

Ideas for later versions, not yet planned in detail:

- **Hebrew and English side by side**, in two columns, as an alternative to one after the other.
- **Long sources that flow onto the next slide by themselves**, sharing each slide's space between
  Hebrew and English the way an article paginates, instead of manual `\mekorbreak`s.
- **A setting for how ח and כ are transliterated** in the English printed (now ḥ and kh: Menaḥot,
  Berakhot), for those who write ch, h or kh.
- **A written-up prose version** of a shiur, made from the same body as its sheet and slides.

## Tests

`tests/run.sh` compiles the test cases in `tests/cases`, the examples in `tests/examples` and a
fresh shiur from `newshiur` (with `buildshiur`) against the working copy of the package, and checks that each builds with no error or missing
character. Each test case also states, in `%!` comment lines, text its PDF must or must not
contain (`tests/check.py` explains the forms). `tests/run.sh pasuk` runs only the files whose
names contain "pasuk". It needs Python 3 and `pdftotext`. A bug fix should come with a small
test case that would have caught it.

## Licence

Copyright 2023–2026 Gabriel Gendler Yom-Tov. Distributed under the
[LaTeX Project Public License](LICENSE), version 1.3c or later.

Contact: shiurtex@thm.mozmail.com

Much of version 2 was developed with [Claude Code](https://claude.com/claude-code).
