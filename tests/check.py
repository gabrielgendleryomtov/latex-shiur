"""Check one compiled test document. Called by run.sh as
    check.py ID SOURCE.tex OUTPUT.pdf OUTPUT.log
and prints one line: "ok ID", or "FAIL ID: " and the reasons.

A test case states what its PDF must show in comment lines starting %!:
    %! expect: TEXT    the text appears in the PDF
    %! absent: TEXT    the text doesn't appear
    %! pages: N        the PDF has N pages
    %! page N: TEXT    the text appears on page N
    %! not page N: TEXT  the text doesn't appear on page N
    %! error: TEXT     the document fails, with TEXT in its log
    %! log: TEXT       the log has TEXT (a warning, say)
    %! not log: TEXT   the log doesn't have TEXT
    %! runs: N         compiled N times (by run.sh), for what is read from the .aux
Text is compared with all whitespace and direction marks removed, since
pdftotext moves spaces around punctuation next to Hebrew. It also moves full
stops and mirrors brackets there, so a TEXT with Hebrew in it is compared
without the punctuation .,:;() (but "..." still counts).
"""

import re
import subprocess
import sys

ident, source, pdf, log = sys.argv[1:5]
DIRECTIVE = re.compile(r"^\s*%!\s*(expect|absent|pages|(?:not )?page (\d+)|(?:not )?log|error|runs):\s*(.*?)\s*$")
INVISIBLE = re.compile(r"[\s‎‏‪-‮⁦-⁩]")


def squash(text):
    return INVISIBLE.sub("", text)


def contains(text, arg):
    arg = squash(arg)
    if re.search(r"[֐-׿]", arg):
        return unpunctuate(arg) in unpunctuate(text)
    return arg in text


def unpunctuate(text):
    return re.sub(r"[.,:;()]", "", text.replace("...", "…"))


def pdftext(*options):
    result = subprocess.run(["pdftotext", *options, pdf, "-"], capture_output=True, text=True)
    return squash(result.stdout)


directives = []
with open(source, encoding="utf-8") as f:
    for line in f:
        m = DIRECTIVE.match(line)
        if m:
            kind = m.group(1).replace("not ", "not").split()[0]
            directives.append((kind, m.group(2), m.group(3)))

try:
    with open(log, encoding="utf-8", errors="replace") as f:
        logtext = f.read()
except FileNotFoundError:
    logtext = ""
failed = re.search(r"^! ", logtext, re.M) is not None
problems = []

errors = [arg for kind, _, arg in directives if kind == "error"]
if errors:
    if not failed:
        problems.append("built, but should have failed")
    for arg in errors:
        if squash(arg) not in squash(logtext):
            problems.append(f"log lacks the error {arg!r}")
elif failed:
    first = re.search(r"^! .*(\n.*){0,2}", logtext, re.M)
    problems.append("error: " + " / ".join(first.group(0).splitlines()))
else:
    for m in re.finditer(r"Missing character: There is no (.*?) in font ([^/!]*)", logtext):
        problems.append(f"missing character {m.group(1)} in {m.group(2)}")
    text = pdftext()
    pages = None
    for kind, page, arg in directives:
        if kind == "expect" and not contains(text, arg):
            problems.append(f"lacks {arg!r}")
        elif kind == "absent" and contains(text, arg):
            problems.append(f"has {arg!r}")
        elif kind == "page" and not contains(pdftext("-f", page, "-l", page), arg):
            problems.append(f"page {page} lacks {arg!r}")
        elif kind == "notpage" and contains(pdftext("-f", page, "-l", page), arg):
            problems.append(f"page {page} has {arg!r}")
        elif kind == "log" and squash(arg) not in squash(logtext):
            problems.append(f"log lacks {arg!r}")
        elif kind == "notlog" and squash(arg) in squash(logtext):
            problems.append(f"log has {arg!r}")
        elif kind == "pages":
            if pages is None:
                info = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
                pages = re.search(r"^Pages:\s*(\d+)", info, re.M).group(1)
            if pages != arg:
                problems.append(f"{pages} pages, not {arg}")

if problems:
    print(f"FAIL {ident}: " + "; ".join(problems))
else:
    print(f"ok {ident}")
