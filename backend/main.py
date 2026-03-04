import uuid
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from ocr import LANGUAGES, extract_words, get_image_dimensions

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

app = FastAPI()


@app.get("/api/languages")
async def languages_endpoint():
    return JSONResponse({
        code: {"label": info["label"], "tts": info["tts"]}
        for code, info in LANGUAGES.items()
    })


@app.post("/api/ocr")
async def ocr_endpoint(image: UploadFile = File(...), lang: str = Form("de")):
    suffix = Path(image.filename).suffix or ".jpg"
    filename = f"{uuid.uuid4().hex}{suffix}"
    filepath = UPLOAD_DIR / filename

    content = await image.read()
    filepath.write_bytes(content)

    words = extract_words(str(filepath), lang=lang)
    img_w, img_h = get_image_dimensions(str(filepath))
    tts_lang = LANGUAGES.get(lang, {}).get("tts", "de-DE")

    return JSONResponse({
        "image_url": f"/uploads/{filename}",
        "image_width": img_w,
        "image_height": img_h,
        "tts_lang": tts_lang,
        "words": words,
    })


# Serve uploaded images
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

# Serve frontend
app.mount("/", StaticFiles(directory=str(BASE_DIR / "frontend"), html=True), name="frontend")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
