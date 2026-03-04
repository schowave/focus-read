# ADR-001: OCR Engine Selection

## Status
Accepted (supersedes earlier decision for Tesseract)

## Context
The app recognizes text on photographed children's book pages. Requirements:
- **Word-level bounding boxes** — each word needs an exact position for the highlight overlay
- **German umlauts** (ä, ö, ü, ß) — primary language is German
- **Multilingual** — English, French, Spanish, Portuguese
- **Runs locally** — no cloud API, no API key
- **CPU-capable** — must run on consumer hardware

## Considered Options

### Tesseract 5.x (pytesseract)
- **Word-level bboxes:** Yes, via `image_to_data()`
- **Umlauts:** Good (with `tesseract-lang` package)
- **CPU:** Yes, very fast
- **Weaknesses:** Single-character confusion (`!` → `i`, `t` → `r`), requires OpenCV preprocessing (CLAHE + Otsu), system dependency (`brew install tesseract`)

### docTR with multilingual PARSeq ✅ Chosen
- **Word-level bboxes:** Yes, native (Page → Block → Line → Word)
- **Umlauts:** Perfect with `Felix92/doctr-torch-parseq-multilingual-v1`
- **CPU:** Yes (~2-5s per page)
- **Strengths:** Transformer-based recognition sees words as whole images → correctly recognizes `aufregend!,`; no preprocessing needed; no system package needed (pure Python/PyTorch)
- **Weaknesses:** Larger dependencies (~400MB PyTorch); first start downloads models from HuggingFace; occasional misrecognitions on decorative fonts

### PaddleOCR v5
- **Word-level bboxes:** Yes
- **Umlauts:** Fixed in v5 with `latin_PP-OCRv5_mobile_rec` model — but only this specific model variant, others still have the bug
- **CPU:** Yes, very lightweight
- **Weaknesses:** Fragile umlaut support (model-dependent), PaddlePaddle framework less common than PyTorch

### Surya v3
- **Word-level bboxes:** Yes (new since v3)
- **Umlauts:** Good (90+ languages)
- **CPU:** No — requires GPU (~16-20GB VRAM)
- **Weaknesses:** High resource consumption, not suitable for consumer hardware

### EasyOCR
- **Word-level bboxes:** No — segment-level only
- **Umlauts:** OK
- **Weaknesses:** Dealbreaker due to missing word-level bboxes; development has slowed

### GOT-OCR2
- **Word-level bboxes:** No
- **Umlauts:** Unknown
- **Weaknesses:** Vision-language model without structured bbox output; requires CUDA GPU; solves a different problem

## Decision
**docTR** with the multilingual PARSeq model.

## Comparison Test on Children's Book Covers

| Criterion | Tesseract 5 | docTR (multilingual) |
|---|---|---|
| `aufregend!,` | ✗ `aufregendi,` | ✅ `aufregend!,` |
| `findet` | ✗ `finder` | ✅ `findet` |
| `Waschbär` | ✅ | ✅ |
| `größten` | ✅ | ✅ |
| `überhaupt` | ✅ | ✅ |
| `für` | ✅ | ✅ |
| `Genau` | ✅ | ✗ `Cenau` |
| Noise filtering | Low noise | More noise (illustrations) |
| System dependency | `brew install tesseract` | None |
| Preprocessing needed | Yes (CLAHE + Otsu) | No |

## Consequences
- No Tesseract system dependency — simplifies setup
- No OpenCV preprocessing needed — less code
- No spell-checker needed — docTR handles punctuation and grammar better
- PyTorch as dependency (~400MB) — larger `pip install`
- First start downloads models from HuggingFace (~200MB) — cached afterwards
