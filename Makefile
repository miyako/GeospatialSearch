PY := .venv/bin/python

.PHONY: all pdf figures check extract setup clean

all: pdf

setup: $(PY)
$(PY): requirements.txt
	python3 -m venv .venv
	$(PY) -m pip install -q -r requirements.txt
	@touch $(PY)

# Build the Japanese PDF (checks code blocks, renders figures, prints via Chrome).
pdf: setup
	$(PY) tools/build.py

# Re-render the localised figures only (build/figures/).
figures: setup
	$(PY) tools/render_figures.py

# Verify the translation without building.
check: setup
	$(PY) -c "import sys; sys.path.insert(0,'tools'); import build; p=build.check(open('src/en.md').read(), open('src/ja.md').read(), 'ja'); print('\n'.join(p) or 'OK'); sys.exit(bool(p))"

# One-time disassembly of the source PDF. Will not overwrite existing files;
# run "$(PY) tools/extract.py --force" to start over (this discards edits to en files and layouts).
extract: setup
	$(PY) tools/extract.py

clean:
	rm -rf build
