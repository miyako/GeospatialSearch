---
description: "End-to-end workflow for localising a 4D technical note: disassemble an English PDF into editable Markdown and figure text, translate (e.g. to Japanese), localise demo data and the companion 4D project, and reassemble a clean PDF repeatably"
applyTo: "document/**,src/**,figures/**,tools/**,style/**,data/**,glossary.md,Makefile,demo/**"
---

# Technical Note Localisation (PDF + 4D demo) — Agent Instructions

## Purpose

Given **an English technical-note PDF** and **its companion 4D demo project**, produce:

1. A translated PDF in a clean, regenerated layout in a style similar to the original.
2. Localised figures, where text drawn inside diagrams is translated.
3. Optionally, demo data replaced with locations or examples relevant to the target audience.
4. A 4D demo project localised with XLIFF.

The user is the editor. The agent builds a **repeatable pipeline**: the user edits plain text, runs one command, and gets a new PDF, as many times as needed. The reference implementation is the `miyako/GeospatialSearch` repository (`tools/`, `style/`, `Makefile`). Copy and adapt it rather than starting from scratch.

These instructions use Japanese (`ja`) as the target language. Substitute the language code, fonts and style rules for other languages.

---

## Non-negotiable rules

- **Code is never translated.** Program code blocks (4D, JS, JSON source, etc.) must stay byte-identical to the English. The build must enforce this mechanically, not by convention.
  - Exception: ```` ```text ```` blocks holding sample *values*, such as coordinates or output, may differ when the demo data is localised.
- **Never patch the original PDF.** Regenerate it from source parts. Patching cannot reflow Japanese text and cannot be repeated.
- **Keep English and translation block-aligned.** `src/en.md` and `src/ja.md` must have the same paragraphs, headings, code blocks and figures in the same order, so they can be diffed side by side.
- **Never overwrite user edits.** Extraction writes only files that don't exist yet, unless `--force` is given. `ja` files are never regenerated automatically.
- **Glossary first.** When the user changes a term, update `glossary.md`, then search and replace in `src/ja.md` and `figures/*.ja.txt`. Ask before mass-replacing.
- **Commit after every user-visible milestone.** Include the user's required trailer, if any, in each commit message.
- **Ask, don't assume**, for design decisions:
  - layout fidelity
  - whether to localise the example data
  - which attributes to add
  - whether names in the UI should follow the language
  - whether to track `Settings/`

---

## Decisions to confirm up front

Ask these one at a time with `ask_user`, giving choices:

1. Output style: a clean regenerated layout in a similar style (recommended), or a pixel-faithful copy.
2. Target language and writing style. For Japanese, です・ます調 with 4D's official Japanese documentation terms.
3. Whether the demo's sample data should be replaced with local examples (e.g. Moroccan sites → Japanese sites).
4. Whether `src/en.md` keeps the original examples. Recommended: yes, as the untouched reference.
5. Where the PDF lives. Recommended: `document/<original-name>.pdf`.

---

## Repository layout (target)

```
document/<name>.pdf                 original English PDF (committed, read-only)
src/en.md                           English body as Markdown (extracted; corrections allowed)
src/ja.md                           translation                    <- user edits
figures/fig-NN.png                  original figure images (extracted)
figures/fig-NN.en.txt               English text per figure, one label per line (OCR)
figures/fig-NN.ja.txt               translated labels, line-aligned  <- user edits
figures/fig-NN-ja.png               optional ready-made replacement (e.g. a localised screenshot)
figures/layout/fig-NN.json          per-label boxes and render overrides
data/                               localised demo data (+ data/<original>/ for reference)
glossary.md                         terminology and style decisions
style/style.css                     print stylesheet
tools/extract.py                    PDF -> Markdown + figures + OCR
tools/render_figures.py             erase English labels, draw translated ones
tools/build.py                      check -> Markdown -> HTML -> Chrome PDF (2 passes)
Makefile                            setup / extract / check / figures / pdf / clean
requirements.txt                    pymupdf, pillow, markdown
README.md                           editor-facing instructions
demo/<project>/                     the 4D project
build/                              output (git-ignored)
```

`.gitignore` must include at least:
- `.venv/`
- `build/`
- `.DS_Store`
- `__pycache__/`
- `demo/*/Data/`
- `demo/*/userPreferences.*/`
- `demo/*/Project/DerivedData/`

---

## Phase 0 — Environment and PDF inspection

Environment, macOS reference setup:
- **Python:** a venv at `.venv`, created by `make setup`.
- **Chrome:** `/Applications/Google Chrome.app`. Edge or Chromium also work.
- **OCR:** `tesseract`.
- **Fonts:** Hiragino in `/System/Library/Fonts`.
  - W3 = light, W4 = regular, W6 = bold.
  - Use the font file names exactly, e.g. `ヒラギノ角ゴシック W4.ttc`.

Inspect the PDF **before** writing heuristics. Use `pymupdf`, page by page, to dump spans with font, size, colour, flags and bbox. Determine:

| Property | How it was detected in 26-09 (Word → Quartz export) |
|---|---|
| Tagged / scanned? | Untagged, real text. If scanned, stop and discuss: OCR of body text is a different project. |
| Page size | US Letter |
| Body text | HelveticaNeue 11 |
| Headings | HelveticaNeue-Medium 12, colour `#2f5496`; level comes from x (72→h2, 90→h3, 108→h4) |
| Title | Medium 18 |
| Code | Syntax-coloured spans; the code colours are the set `{0x385623, 0x2E75B6, 0x548235, 0x7F6000, 0x203864, 0x2F5597, 0x1F4E79}`. Check for monospace fonts too. |
| Captions | Italic lines with x > 92 |
| Bullets | Glyphs in the `SymbolMT` / `Wingdings` fonts |
| Tables | Smaller text (10 pt) in a grid |
| Header/footer | Cut-off by y: footer at y0 > 710. Check that no caption sits below the cut-off (fig-16's caption was at y = 701). |
| Cover and TOC | Pages 1–2, handled specially. The TOC is regenerated, never translated. |
| Figures | Raster images (`page.get_images`). Record the placed width in points, `width_pt`, for the rebuild. |

These values are document-specific. **Re-derive them for every new PDF.** Print a histogram of (font, size, colour) to find them quickly.

---

## Phase 1 — Disassembly (`tools/extract.py`)

### Body → `src/en.md`

- Walk lines in reading order and classify each one: heading, code, caption, bullet, table row or body.
- **Paragraph joining:** start a new paragraph when either:
  - the vertical gap to the previous line is > 3 pt, or
  - the previous line ends with `.` or `:` and is short (x1 < 470, i.e. it doesn't reach the right margin).
- **Code blocks:** group consecutive code lines into one fenced block.
  - Guess the language from content (`4d`, `js`, `json`, `html`, `text`).
  - Indentation = leading spaces // 4 when there are 4 or more spaces. Otherwise use 1 level when x > the block's minimum x + 10.
  - Indent with tabs or 4 spaces, consistently.
- **Inline formatting:** bold spans → `**…**`, monospace or code-coloured inline spans → `` `…` ``.
- **Figures:** emit `![caption](fig-NN)` where the image sits, numbered in document order.
- **Tables:** emit a Markdown table.
- **Validate:** compare the number of code blocks, figures and headings against your own count from the PDF. Read `en.md` once end to end, looking for broken joins or merged code lines.

### Figures

- Extract each image to `figures/fig-NN.png`. Composite RGBA images onto white first.
- OCR with `tesseract <png> - --psm 11 tsv`. Group words into lines by block/paragraph/line numbers. Filter noise (single characters, low confidence, pure punctuation).
- Write `figures/fig-NN.en.txt` with one label per line.
- Write `figures/layout/fig-NN.json`: `{source, page, width_pt, localize, items:[{box:[x,y,w,h]}]}`, one item per line.
- **Check the OCR by eye and correct `en.txt`.** Typical errors: `4D` read as `AD`, `×`, `θ`, `=`, units. Correct the English file, because it is the reference that line N maps to.
- Mark screenshots of the app UI `"localize": false`. Don't overlay text on screenshots. Ask the user for a localised screenshot instead (see Phase 3).

---

## Phase 2 — Translation

### Body (`src/ja.md`)

- Translate paragraph by paragraph, keeping Markdown structure, order and figure references `![…](fig-NN)`.
- Translate captions; keep `fig-NN`.
- Leave code fences untouched.
- Style for Japanese:
  - です・ます調.
  - Half-width alphanumerics, no space between Japanese and Latin text (`4D.Vector型`).
  - Full-width brackets `（）` and `：` in prose.
  - Use terms from 4D's official Japanese documentation: Webエリア, エンティティセレクション, データストア, 引数, メソッド, フォーム, コレクション.
  - First occurrence of a technical term: 日本語（English）.
- Record every terminology choice in `glossary.md` (`| English | 日本語 | Notes |`), plus proper nouns used in examples.

### Figure text (`figures/fig-NN.ja.txt`)

The file has the same number of lines as `fig-NN.en.txt`. For each line N:
- **Identical to the English:** the label is left untouched. Use this for code, numbers and identifiers such as `nameEN`.
- **Empty:** the English is erased and nothing is drawn. Use this to merge two lines into one.
- **Anything else:** the English is erased and the translation is drawn in its place.

Keep labels short. Japanese is denser, but boxes are fixed.

---

## Phase 3 — Figure rendering (`tools/render_figures.py`)

For each layout with `localize: true`:

1. Open the image and composite it onto white.
2. For each item whose `ja` text differs from `en`:
   - Sample the **background colour** as the most common colour in a ring around the box, then erase the box with it (padding 3 px, `erase_pad` to override).
   - Sample the **foreground colour** from the darkest pixels that differ from the background inside the original box.
   - **Size:** estimate it from the English text width, clamp it by the box height, and make sure the text stays inside the image.
   - **Snap sizes** so labels of the same rank match: group within an 8 % tolerance, and absorb singletons within 30 %.
   - Draw with the requested weight (default regular) and alignment (default centre).
3. Write the result to `build/figures/fig-NN.png`.

Supported per-item overrides in the layout JSON:
- `scale` or `size` (px)
- `weight`: `light`, `regular` or `bold`
- `align`: `left` or `center`
- `dx` / `dy` offsets
- `box` (replaces the OCR box)
- `bg` / `fg` as `[r,g,b,a]`
- `erase_pad`

Per-figure option: `"replace": "fig-NN-ja.png"` copies a ready-made image from `figures/` instead of overlaying text. Use this for localised app screenshots. The build keeps the original `width_pt`, so a different aspect ratio only changes the height.

**Typical manual fixes (from 26-09):**
- OCR merged two labels: give an explicit `box`.
- Legend text next to coloured dots: shift the boxes so the erase doesn't remove the dots, and left-align the text.
- A title came out too small: set `scale` 1.3.
- List-like labels: set `align: left`.

**Visual verification is mandatory.** The image viewer shows one image per call, so compose **contact sheets**: several figures resized to the same width and pasted side by side. Check for clipped text, leftover English fragments, wrong colours and misalignment.

---

## Phase 4 — Reassembly (`tools/build.py`)

1. **Check:**
   - Every non-`text` code block in `ja.md` is byte-identical to the one at the same position in `en.md`. Use the regex ```` ^```[^\n]*\n.*?^```$ ```` (multiline, dotall) and skip blocks whose fence starts with ```` ```text ````.
   - The set of figure references matches.
   - Refuse to build on any mismatch, and print a clear diff of what differs.
2. **Render figures** (Phase 3).
3. **Markdown → HTML** with python-markdown (extensions `fenced_code`, `tables`, `attr_list`).
   - Figures become `<figure><img style="width:{width_pt}pt"><figcaption>`.
   - Build the cover from the title block, and generate the TOC from the headings.
4. **HTML → PDF** with headless Chrome: `--headless=new --no-pdf-header-footer --print-to-pdf=<out> file://<html>`.
   - CSS `@page` margin boxes give page numbers (Chrome 131+).
   - Use `overflow-wrap: anywhere` in `pre` so long code lines wrap instead of overflowing.
5. **Second pass for TOC page numbers:** find each heading in the first-pass PDF with `pymupdf` `search_for`, inject the page numbers, and print again.
6. Print the page count. Compare it to the original: a difference of ±1–2 pages is normal for Japanese.

`style/style.css`: match the original's look.
- Heading colour, sizes, margins and code colours.
- A Japanese font stack: `"Hiragino Sans", "Hiragino Kaku Gothic ProN", sans-serif`, with a monospace font for code.
- Line height about 1.7 for Japanese body text.

Makefile targets:
- `setup` (venv + requirements)
- `extract` (never overwrites)
- `check`
- `figures`
- `pdf` (the default)
- `clean`

**Prove that the check works:** deliberately change a character in a code block in `ja.md`, run `make check`, confirm it fails, then revert.

---

## Phase 5 — The edit loop

- Write a `README.md` section for the editor covering:
  - which files to edit
  - the figure-line rules
  - the layout overrides
  - `make`, `make check` and `make figures`
  - how to re-extract safely
- After each round of user edits:
  1. `make`.
  2. Inspect the pages or figures that changed.
  3. Commit with a message describing what changed.
- When the user changes a term in the glossary, commit the glossary on its own if asked. Then report the remaining occurrences of the old term (`grep -c`) in `ja.md` and the figures, and offer to replace them.

---

## Phase 6 — Localising the demo data (optional)

Example: replace Moroccan cities and tourist sites with Japanese ones.

### Data format

- **Keep the original record format exactly** and add a field for the new language: `nameJa` next to `nameFr`/`nameEn`/`nameAr`. Ask the user which fields to keep.
- Cities: `{item, nameFr, nameEn, nameAr, nameJa, population, coord:[lat,lon]}`.
- Sites: the same, with `nbLiens` (the sitelinks count) in place of `population`.
- Store the originals in `data/<original-country>/` for reference.

### Sourcing from Wikidata

- **Primary:** the SPARQL query service at `query.wikidata.org`. It may be in an outage: 504 timeouts, or 429 errors limited to 1 request per minute.
- **Fallback:**
  1. Run the query on the **QLever** mirror, `https://qlever.dev/api/wikidata`. Rank by `?item wikibase:sitelinks ?l`.
  2. Fetch labels and claims from the Wikidata API, `action=wbgetentities`, 50 IDs per call, `props=labels|claims|sitelinks`, `languages=fr|en|ar|ja`.
  3. Send a descriptive User-Agent header and sleep about 1 s between calls.
- Sites: filter on country (P17 = Q17 for Japan) and require a coordinate (P625). Restrict to tourist types: shrines/temples, castles, parks, museums, mountains, World Heritage sites, landmarks, towers, gardens. Order by sitelinks and take the top N.
- Cities: city-type classes (for Japan Q494721, Q1137833, Q17221353, Q1059478), ordered by population or sitelinks. **Check that the capital is included.** Tokyo (Q1490) is not typed as a city and had to be added manually.
- Population: the preferred-rank P1082 value, otherwise the one with the latest P585 date.
- Remove office buildings, duplicates (e.g. a World Heritage *area* duplicating its temple) and non-tourist items. Tell the user what was excluded.
- Report empty labels, e.g. how many records have no Arabic name.

### Rewriting the examples in `ja.md` and the figures

- Choose equivalents for each example city (e.g. Marrakesh → Kyoto, Casablanca → Osaka).
- **Compute every number from the new data.** Never invent values.
  - Use haversine distances with R = 6371 km.
  - Keep DMS formatting identical to the demo code: degrees, integer minutes, seconds rounded to an integer, with 60-second carry-over.
- Replace in the text:
  - the country names
  - the example city names
  - coordinate samples in ```` ```text ```` blocks
  - the coordinate arrays inside JSON examples, only if they are `text` blocks
  - results tables (nearest sites with distances)
  - the counts used in the prose
- Update the figure labels that show sample coordinates or field lists, and re-render them.
- Leave the code blocks alone. If the demo code changes (e.g. the file name or new fields), tell the user that the document's code no longer matches the demo, and ask how to handle it.

---

## Phase 7 — The 4D demo project

Follow the repository's existing 4D instruction files: localisation, startup, variable declarations, method visibility, etc. Key points from 26-09:

- **Git:** ignore `Data/`, `userPreferences.*/` and `Project/DerivedData/`. Ask whether to track `Settings/`.
- **Line endings:** don't convert them. Preserve each file's CRLF or LF, and write new 4D code with the same endings as the file being edited.
- **Command tokens:** before writing any `Command:CNNN` / `Constant:KNN:NN`, grep the project for that exact token. If it isn't found, write the plain name with no token suffix.
- **XLIFF:**
  - Files go in `Resources/en.lproj/<Form>EN.xlf` and `Resources/ja.lproj/<Form>JA.xlf`, as XLIFF 1.2 with `source-language="en"`.
  - Use ID-based trans-units at the `<body>` level.
  - Form JSON uses `":xliff:<ID>"` in `text`, `windowTitle` and list box header `text`.
  - Expressions use `Localized string("<ID>")`.
  - For counts, use a template with a placeholder: `Replace string(Localized string("Welcome_SiteCount"); "{n}"; String(siteCount))`, because word order differs between languages (`{n} touristic sites` vs `観光名所 {n} 件`).
  - Don't duplicate 4D's built-in `Common*` IDs; menus usually already use them.
  - Strip stray source-language literals from code (e.g. French `"aucun"` → an XLIFF entry).
  - Update the English text when the data changed (e.g. "in Morocco" → "in Japan"), and tell the user.
- **Names that follow the UI language:** add a computed attribute in the entity classes.

  ```4d
  Function get name() : Text
  	var $lang : Text
  	$lang:=Get database localization(Current localization)
  	Case of
  		: ($lang="ja")
  			return This.nameJA
  		Else
  			return This.nameEN
  	End case

  Function orderBy name($event : Object) : Text
  	// same Case of, returning "nameJA "+$event.operator etc.
  ```

  - Without `orderBy`, sorting on the computed attribute is sequential: `get` is evaluated for every entity.
  - The `orderBy` function returns a sort string on the stored attribute, so the sort is native.
- **Startup UI:** don't chain blocking `DIALOG`s from `On Startup`, because that leaves a modal window behind the next one. Instead:
  1. `run` with no arguments looks for an existing window (`WINDOW LIST`, `Window process=1`, title match) and brings it to the front with `CALL FORM` + `SET WINDOW RECT`. Otherwise it calls `CALL WORKER(1; Current method name; {})`.
  2. In the worker: `SET MENU BAR(1)`, `Open form window`, `SET WINDOW TITLE(<localised title>)`, then `DIALOG(form; *)`.
  3. The "next" button has the Accept action. Its object method opens the next form with `DIALOG(…; *)` and copies the window title.

### Headless verification with tool4d

tool4d is at `/Applications/tool4d/<ver>/<build>/tool4d.app/Contents/MacOS/tool4d`.

1. Copy `Project/` and `Resources/` (and `Data/` if needed) to a temporary directory, never the repository.
2. Add a test method there that writes results to a file and calls `QUIT 4D`.
3. Run:

```sh
tool4d --project=/tmp/x/Project/<name>.4DProject --startup-method=<test> --skip-onstartup [--dataless | --data=/tmp/x/Data/data.4DD]
```

Useful tests:
- **Compile:** `Compile project({targets: []})` checks syntax only. Expect `success: true` and `errors: []`.
- **XLIFF:** `SET DATABASE LOCALIZATION("ja")`, then `Localized string(<ID>)` for sample IDs, and the same for `en`. A language without a `.lproj` folder can't be selected, so the localisation silently stays as it was.
- **orderBy:** compare `orderBy("name")` against `orderBy("nameJA")` IDs for asc and desc. To prove the function is actually called, temporarily make it return `"ID desc"` in the temporary copy.

Forms can't be displayed by tool4d. Ask the user to check window flow and label fit in 4D, especially with longer Japanese labels.

---

## Verification checklist

- [ ] `make check` passes, and a deliberate code edit makes it fail.
- [ ] `make` builds the PDF. The page count is close to the original, and the TOC page numbers are correct.
- [ ] Every figure has been visually checked on a contact sheet. Screenshots are replaced or flagged.
- [ ] No source-language leftovers: grep `ja.md` and `*.ja.txt` for old place names, old coordinates and long ASCII sentences.
- [ ] The glossary is consistent; grep for alternative spellings of key terms.
- [ ] The demo data numbers in the text were recomputed from the committed JSON.
- [ ] 4D: compile check passes, XLIFF resolves in every language, and no unverified tokens were written.
- [ ] Temporary files (`/tmp/...`, test copies) are removed.
- [ ] The README describes the current workflow.
- [ ] Everything is committed; `git status` is clean or the user has been told what remains.

## Pitfalls encountered

- A caption just above the footer cut-off was dropped. Check each figure's caption.
- OCR boxes that merge two labels, or include legend dots: fix them with `box` / `dx`.
- `fig-11-ja.png` was placed in `build/figures/` by the user. `build/` is overwritten and ignored, so move such files into `figures/`.
- Re-saving 4D methods in the 4D editor can change line endings, which makes whole-file diffs. Mention it, don't "fix" it silently.
- The Wikidata SPARQL service can be down for long periods. Use the QLever + `wbgetentities` fallback instead of waiting.
