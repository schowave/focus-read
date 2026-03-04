.PHONY: install run clean test lint

install: venv
	@echo "✓ Ready. Run 'make run' to start."

venv: backend/requirements.txt
	python3 -m venv venv
	venv/bin/pip install -r backend/requirements.txt
	@touch venv

run: venv
	venv/bin/python backend/main.py

lint: venv
	venv/bin/pip install -q ruff
	venv/bin/ruff check backend/

test: venv
	@echo "Running OCR on example image..."
	@venv/bin/python -c "\
		import sys; sys.path.insert(0, 'backend'); \
		from ocr import extract_words; \
		words = extract_words('examples/buchcover-waschbaer.webp'); \
		print('\n'.join(f'{i+1:2d}. {w[\"text\"]}' for i, w in enumerate(words))); \
		print(f'\n{len(words)} words detected')"

clean:
	rm -rf venv uploads/*
