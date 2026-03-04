import re

import cv2
import numpy as np
import pytesseract
from spellchecker import SpellChecker

# Mapping: Tesseract lang code → (spellchecker lang, TTS lang)
LANGUAGES = {
    "deu": {"spell": "de", "tts": "de-DE", "label": "Deutsch"},
    "eng": {"spell": "en", "tts": "en-US", "label": "English"},
    "fra": {"spell": "fr", "tts": "fr-FR", "label": "Français"},
    "spa": {"spell": "es", "tts": "es-ES", "label": "Español"},
    "por": {"spell": "pt", "tts": "pt-PT", "label": "Português"},
}

_spellers: dict[str, SpellChecker] = {}


def _get_speller(lang: str) -> SpellChecker | None:
    """Get or create a SpellChecker for the given Tesseract language."""
    spell_lang = LANGUAGES.get(lang, {}).get("spell")
    if not spell_lang:
        return None
    if spell_lang not in _spellers:
        try:
            _spellers[spell_lang] = SpellChecker(language=spell_lang)
        except Exception:
            return None
    return _spellers[spell_lang]


def preprocess(image_path: str) -> np.ndarray:
    """Grayscale → CLAHE contrast enhancement → Otsu binarization."""
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return binary


def extract_words(image_path: str, lang: str = "deu") -> list[dict]:
    """Run Tesseract OCR and return word-level bounding boxes."""
    processed = preprocess(image_path)
    data = pytesseract.image_to_data(processed, lang=lang, output_type=pytesseract.Output.DICT)

    spell = _get_speller(lang)

    words = []
    for i in range(len(data["text"])):
        text = data["text"][i].strip()
        conf = int(data["conf"][i])
        if not text or conf < 30:
            continue
        words.append({
            "text": text,
            "x": data["left"][i],
            "y": data["top"][i],
            "w": data["width"][i],
            "h": data["height"][i],
            "conf": conf,
            "_sort": (data["block_num"][i], data["par_num"][i], data["line_num"][i]),
        })

    # Sort by block → paragraph → line → left-to-right
    words.sort(key=lambda w: (*w["_sort"], w["x"]))

    # Remove sort key, apply conservative spell-check, filter noise
    for w in words:
        del w["_sort"]
        if spell:
            w["text"] = _correct_word(w["text"], w["conf"], spell)

    # Filter out non-word noise (barcode fragments, single symbols)
    words = [w for w in words if _is_real_word(w["text"], spell)]

    return words


def _correct_word(text: str, conf: int, spell: SpellChecker) -> str:
    """Spell-check a word, preserving surrounding punctuation.

    Only corrects when:
    - Confidence is below 80 (high-confidence words are likely correct)
    - Edit distance is exactly 1 (avoids mangling compound words/names)
    """
    if conf >= 80:
        return text

    # Split into: leading punct, core word, trailing punct
    m = re.match(r'^([^\w]*)(.+?)([^\w]*)$', text, re.UNICODE)
    if not m:
        return text
    prefix, core, suffix = m.groups()

    lower = core.lower()
    if lower in spell or len(core) <= 2:
        return text

    # Only accept corrections with edit distance 1
    candidates = spell.candidates(lower)
    if not candidates:
        return text
    edit1 = {c for c in candidates if _edit_distance(lower, c) == 1}
    if not edit1:
        return text

    correction = min(edit1, key=lambda c: -spell.word_usage_frequency(c))

    # Preserve original capitalization
    if core[0].isupper():
        correction = correction[0].upper() + correction[1:]

    return prefix + correction + suffix


def _edit_distance(a: str, b: str) -> int:
    """Simple Levenshtein distance."""
    if len(a) < len(b):
        return _edit_distance(b, a)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a):
        curr = [i + 1]
        for j, cb in enumerate(b):
            curr.append(min(prev[j + 1] + 1, curr[j] + 1, prev[j] + (ca != cb)))
        prev = curr
    return prev[-1]


def _is_real_word(text: str, spell: SpellChecker | None) -> bool:
    """Filter out barcode/logo noise — keep only plausible words."""
    core = re.sub(r'[^\w]', '', text, flags=re.UNICODE)
    if not core:
        return False
    # Short fragments (1-2 chars) that aren't common words
    if len(core) <= 2 and spell and core.lower() not in spell:
        return False
    # Pure numbers (barcodes)
    if core.isdigit():
        return False
    # Contains digits mixed with letters (barcode fragments)
    if any(c.isdigit() for c in core) and any(c.isalpha() for c in core):
        return False
    # Contains parentheses/brackets (OCR artifacts)
    if re.search(r'[(){}\[\]]', text):
        return False
    return True


def get_image_dimensions(image_path: str) -> tuple[int, int]:
    """Return (width, height) of the original image."""
    img = cv2.imread(image_path)
    h, w = img.shape[:2]
    return w, h
