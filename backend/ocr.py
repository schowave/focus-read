import re

from doctr.io import DocumentFile
from doctr.models import ocr_predictor, from_hub

# TTS language mapping (docTR's multilingual model handles all languages)
LANGUAGES = {
    "de": {"tts": "de-DE", "label": "Deutsch"},
    "en": {"tts": "en-US", "label": "English"},
    "fr": {"tts": "fr-FR", "label": "Français"},
    "es": {"tts": "es-ES", "label": "Español"},
    "pt": {"tts": "pt-PT", "label": "Português"},
}

# Load models once at startup
_predictor = None


def _get_predictor():
    global _predictor
    if _predictor is None:
        reco_model = from_hub("Felix92/doctr-torch-parseq-multilingual-v1")
        reco_model.eval()
        _predictor = ocr_predictor(det_arch="db_resnet50", pretrained=True)
        _predictor.reco_predictor.model = reco_model
    return _predictor


def extract_words(image_path: str, lang: str = "de") -> list[dict]:
    """Run docTR OCR and return word-level bounding boxes in pixel coords."""
    predictor = _get_predictor()
    doc = DocumentFile.from_images(image_path)
    result = predictor(doc)

    page = result.pages[0]
    h, w = page.dimensions  # (height, width) in pixels

    words = []
    for block in page.blocks:
        for line in block.lines:
            for word in line.words:
                conf = round(word.confidence * 100)
                text = word.value.strip()
                if not text or conf < 85:
                    continue
                (x1, y1), (x2, y2) = word.geometry
                words.append({
                    "text": text,
                    "x": round(x1 * w),
                    "y": round(y1 * h),
                    "w": round((x2 - x1) * w),
                    "h": round((y2 - y1) * h),
                    "conf": conf,
                })

    # docTR already returns words in reading order (block → line → word)
    # Just filter noise
    words = [w for w in words if _is_real_word(w["text"])]

    return words


def _is_real_word(text: str) -> bool:
    """Filter out barcode/logo noise."""
    core = re.sub(r'[^\w]', '', text, flags=re.UNICODE)
    if not core:
        return False
    # Single-char: only allow common short words
    if len(core) == 1 and core.lower() not in ("a", "i", "o"):
        return False
    # Pure numbers (barcodes)
    if core.isdigit():
        return False
    # Contains digits (barcode fragments like "44674_", "16_")
    if any(c.isdigit() for c in core):
        return False
    # Parentheses/brackets (OCR artifacts)
    if re.search(r'[(){}\[\]]', text):
        return False
    # URLs and domains (contain dots mid-word)
    if re.search(r'\w\.\w', text):
        return False
    return True


def get_image_dimensions(image_path: str) -> tuple[int, int]:
    """Return (width, height) of the image."""
    from PIL import Image
    img = Image.open(image_path)
    return img.size
