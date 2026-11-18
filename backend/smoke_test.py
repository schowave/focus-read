"""Smoke tests run by `mise run test` (and CI): OCR on the example image, app serves the frontend."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi.testclient import TestClient

from main import app
from ocr import extract_words

EXAMPLE = (
    Path(__file__).resolve().parent.parent / "examples" / "buchcover-waschbaer.webp"
)


def test_ocr_on_example_image() -> None:
    words = extract_words(str(EXAMPLE))
    assert len(words) > 0, "No words detected"
    texts = [w["text"] for w in words]
    print(f"{len(words)} words detected: {texts}")
    assert any("Waschbär" in t for t in texts), "Expected word Waschbär not found"


def test_app_serves_frontend() -> None:
    resp = TestClient(app).get("/")
    assert resp.status_code == 200, resp.status_code
    print("FastAPI serves frontend OK")


if __name__ == "__main__":
    test_ocr_on_example_image()
    test_app_serves_frontend()
