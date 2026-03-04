import cv2
import numpy as np
import pytesseract
from pathlib import Path


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

    # Remove sort key from output
    for w in words:
        del w["_sort"]

    return words


def get_image_dimensions(image_path: str) -> tuple[int, int]:
    """Return (width, height) of the original image."""
    img = cv2.imread(image_path)
    h, w = img.shape[:2]
    return w, h
