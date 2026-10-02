# GeospatialSearch

Geospatial Search with 4D, ORDA and 4D.Vector
By Karim Meghraoui, Technical Support Engineer, 4D Morocco.
Technical Note 26-09

## Japanese translation

The original PDF (`document/26-09_GeospatialSearch.pdf`) has been disassembled into
editable plain-text parts. Edit the Japanese files, then run `make` to reassemble the PDF.
Repeat as often as needed.

```
document/26-09_GeospatialSearch.pdf   original (English)
src/en.md                             English body text (reference, from the PDF)
src/ja.md                             Japanese body text            <- edit
figures/fig-NN.png                    original figure images
figures/fig-NN.en.txt                 English text in each figure (one line per label)
figures/fig-NN.ja.txt                 Japanese text in each figure  <- edit
figures/layout/fig-NN.json            position/size of each label (fine-tuning)
glossary.md                           terminology and style decisions
style/style.css                       page layout and typography
build/26-09_GeospatialSearch_ja.pdf   output (not committed)
```

### Build

Requires macOS (Hiragino fonts), Python 3, and Google Chrome (or Edge/Chromium) for PDF printing.

```sh
make          # check + render figures + build/26-09_GeospatialSearch_ja.pdf
make check    # only verify that code blocks and figure references are intact
make figures  # only re-render build/figures/*.png
```

### Editing the body text (`src/ja.md`)

- Markdown: `##`/`###`/`####` headings, `-` lists, `**bold**`, tables.
- Code blocks (```` ``` ````) must stay byte-identical to `src/en.md`; the build refuses to run otherwise.
- `![caption](fig-NN)` places a figure; translate the caption, keep `fig-NN`.
- Paragraphs are in the same order as `src/en.md`, so the two files can be compared side by side.
- The table of contents and its page numbers are generated automatically.

### Editing figure text (`figures/fig-NN.ja.txt`)

Line *N* of `fig-NN.ja.txt` replaces line *N* of `fig-NN.en.txt` at the same position in the image.
The number of lines must match.

- Line identical to English: left untouched (use for code, numbers, proper names).
- Empty line: English text is erased and nothing is drawn (to merge two lines into one).
- Anything else: English is erased and the Japanese is drawn in its place, auto-sized to fit.

Optional per-label tweaks in `figures/layout/fig-NN.json` (`items[N-1]`):
`"scale": 1.2`, `"size": 28` (px), `"weight": "light"|"regular"|"bold"`,
`"align": "left"|"center"`, `"dx"`/`"dy"` (px offset), `"box": [x, y, w, h]`, `"bg"`/`"fg": [r, g, b, a]`.

`fig-11` is a screenshot of the application UI; it is used unchanged (`"localize": false`).
Replace `figures/fig-11.png` with a Japanese screenshot if one is available.

### Re-extracting

`make extract` disassembles the PDF again but never overwrites existing files.
`.venv/bin/python tools/extract.py --force` starts over from scratch (discards layout tweaks
and `en` corrections; `ja` files are not touched).
