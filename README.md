# Focus Read

A reading aid for children: capture a book page, then read word-by-word with highlighting and text-to-speech.

## How it works

1. Take a photo of a book page (or upload an image)
2. OCR detects every word with its position on the page
3. Tap/click to advance through words one at a time
4. Each word is highlighted and spoken aloud

## Prerequisites

- **Python 3.10+**

That's it — no system-level OCR engine needed. The ML models are downloaded automatically on first run.

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

## Supported languages

German, English, French, Spanish, Portuguese — select in the UI before capturing.

## Tech stack

- **Backend:** FastAPI
- **Frontend:** Vanilla HTML/JS/CSS
- **OCR:** docTR (PyTorch) with multilingual PARSeq recognition model
- **TTS:** Web Speech API (rate 0.8)
