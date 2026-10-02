#!/usr/bin/env python3
"""Assemble the translated PDF.

  src/<lang>.md + build/figures/*.png + style/style.css
      -> build/<lang>.html -> build/26-09_GeospatialSearch_<lang>.pdf

Before building, verifies that every code block in the translation is
byte-identical to the English source and that every figure is referenced.
"""
import argparse
import html
import re
import shutil
import subprocess
import sys
from pathlib import Path

import json

import markdown
import pymupdf

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
]
CODE_RE = re.compile(r"^```[^\n]*\n.*?^```$", re.S | re.M)
FIG_RE = re.compile(r"!\[[^\]]*\]\((fig-\d+)\)")


def check(en: str, tr: str, lang: str) -> list:
    problems = []
    en_code, tr_code = CODE_RE.findall(en), CODE_RE.findall(tr)
    if len(en_code) != len(tr_code):
        problems.append(f"en.md has {len(en_code)} code blocks, {lang}.md has {len(tr_code)}")
    for i, (a, b) in enumerate(zip(en_code, tr_code), 1):
        if a != b:
            first = next((l for l in zip(a.splitlines(), b.splitlines()) if l[0] != l[1]), None)
            problems.append(f"code block #{i} differs from English source: {first}")
    en_figs, tr_figs = FIG_RE.findall(en), FIG_RE.findall(tr)
    if en_figs != tr_figs:
        problems.append(f"figure references differ: en={en_figs} {lang}={tr_figs}")
    return problems


def fig_width(name: str) -> float:
    """Printed width of the figure in the original PDF, in points."""
    layout = ROOT / "figures" / "layout" / f"{name}.json"
    return json.loads(layout.read_text())["width_pt"]


def slug(n: int) -> str:
    return f"sec-{n:02d}"


def to_html(md_text: str, toc_pages: dict) -> str:
    lines = md_text.split("\n")
    # Cover: the title (# ...) and the paragraphs before the first ## heading.
    first_h2 = next(i for i, l in enumerate(lines) if l.startswith("## "))
    cover_md = "\n".join(lines[:first_h2])
    body_md = "\n".join(lines[first_h2:])
    cover_parts = [p.strip() for p in cover_md.split("\n\n") if p.strip()]
    title = cover_parts[0].lstrip("# ").strip()
    cover = (f'<section class="cover"><h1>{html.escape(title)}</h1>'
             + "".join(f"<p>{html.escape(p)}</p>" for p in cover_parts[1:]) + "</section>")

    # Give every heading a stable id and collect the TOC.
    toc, counter = [], 0

    def heading(m):
        nonlocal counter
        counter += 1
        level, text = len(m.group(1)), m.group(2).strip()
        toc.append((level, text, slug(counter)))
        return f"{m.group(1)} {text} {{#{slug(counter)}}}"

    in_code = False
    out = []
    for l in body_md.split("\n"):
        if l.startswith("```"):
            in_code = not in_code
        if not in_code:
            l = re.sub(r"^(#{2,4}) (.+)$", heading, l)
        out.append(l)
    body_md = "\n".join(out)

    body = markdown.markdown(body_md, extensions=["fenced_code", "tables", "attr_list"])
    body = re.sub(
        r'<p><img alt="([^"]*)" src="(fig-\d+)" /></p>',
        lambda m: (f'<figure><img src="figures/{m.group(2)}.png" alt="" style="width:{fig_width(m.group(2))}pt">'
                   + (f"<figcaption>{m.group(1)}</figcaption>" if m.group(1) else "")
                   + "</figure>"),
        body)

    toc_title = "目次" if re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", md_text) else "Table of Contents"
    toc_html = [f'<section class="toc"><h2 class="toc-title">{toc_title}</h2><ol>']
    for level, text, anchor in toc:
        page = toc_pages.get(anchor, "")
        label = html.escape(re.sub(r"[*`]", "", text))
        toc_html.append(f'<li class="l{level}"><a href="#{anchor}"><span class="t">{label}</span>'
                        f'<span class="p">{page}</span></a></li>')
    toc_html.append("</ol></section>")

    css = (ROOT / "style" / "style.css").read_text(encoding="utf-8")
    return (f'<!doctype html><html lang="ja"><head><meta charset="utf-8">'
            f"<title>{html.escape(title)}</title><style>{css}</style></head><body>"
            f'{cover}{"".join(toc_html)}<main>{body}</main></body></html>'), toc


def chrome() -> str:
    for c in CHROME_CANDIDATES:
        if Path(c).exists():
            return c
    sys.exit("No Chrome/Edge/Chromium found for printing to PDF")


def print_pdf(html_path: Path, pdf_path: Path):
    subprocess.run([chrome(), "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--run-all-compositor-stages-before-draw", "--virtual-time-budget=10000",
                    f"--print-to-pdf={pdf_path}", html_path.as_uri()],
                   check=True, capture_output=True)


def find_pages(pdf_path: Path, toc) -> dict:
    doc = pymupdf.open(pdf_path)
    pages, start = {}, 2  # skip cover and table of contents
    for level, text, anchor in toc:
        needle = re.sub(r"[*`]", "", text)
        for pno in range(start, len(doc)):
            if doc[pno].search_for(needle):
                pages[anchor] = pno + 1
                start = pno
                break
    return pages


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lang", default="ja", help="translation to build (src/<lang>.md)")
    ap.add_argument("--skip-figures", action="store_true")
    args = ap.parse_args()

    en = (ROOT / "src" / "en.md").read_text(encoding="utf-8")
    tr = (ROOT / "src" / f"{args.lang}.md").read_text(encoding="utf-8")
    problems = check(en, tr, args.lang)
    if problems:
        print("Translation check failed:", *problems, sep="\n  ", file=sys.stderr)
        return 1
    print("check: code blocks identical, figures referenced")

    if not args.skip_figures:
        subprocess.run([sys.executable, str(ROOT / "tools" / "render_figures.py")], check=True)

    BUILD.mkdir(exist_ok=True)
    html_path = BUILD / f"{args.lang}.html"
    pdf_path = BUILD / f"26-09_GeospatialSearch_{args.lang}.pdf"
    tmp_pdf = BUILD / f".{args.lang}.pass1.pdf"

    page_html, toc = to_html(tr, {})
    html_path.write_text(page_html, encoding="utf-8")
    print_pdf(html_path, tmp_pdf)
    pages = find_pages(tmp_pdf, toc)
    page_html, _ = to_html(tr, pages)
    html_path.write_text(page_html, encoding="utf-8")
    print_pdf(html_path, pdf_path)
    tmp_pdf.unlink(missing_ok=True)

    missing = [t for _, t, a in toc if a not in pages]
    if missing:
        print("warning: page numbers not found for:", *missing, sep="\n  ")
    print(f"wrote: {pdf_path.relative_to(ROOT)} ({len(pymupdf.open(pdf_path))} pages)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
