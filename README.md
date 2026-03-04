# Focus Read

A reading aid for children: capture a book page, then read word-by-word with highlighting and text-to-speech.

## How it works

1. Take a photo of a book page (or upload an image)
2. OCR detects every word with its position on the page
3. Tap/click to advance through words one at a time
4. Each word is highlighted and spoken aloud (German TTS)

## Prerequisites

- **Python 3.10+**
- **Tesseract 5.x** with German language data:
  ```bash
  # macOS
  brew install tesseract tesseract-lang

  # Ubuntu/Debian
  sudo apt install tesseract-ocr tesseract-ocr-deu
  ```

## Quick start

```bash
make install   # create venv + install dependencies
make run       # start server on http://localhost:8000
```

Open `http://localhost:8000` on your phone/tablet (same network).

## Commands

| Command       | Description                          |
|---------------|--------------------------------------|
| `make install`| Create virtualenv and install deps   |
| `make run`    | Start the server on port 8000        |
| `make test`   | Run OCR on `shopping.webp` (smoke test) |
| `make clean`  | Remove virtualenv and uploaded files |

## Tech stack

- **Backend:** FastAPI + pytesseract + OpenCV
- **Frontend:** Vanilla HTML/JS/CSS
- **OCR:** Tesseract 5.x (word-level bounding boxes, German language model)
- **TTS:** Web Speech API (`de-DE`, rate 0.8)
