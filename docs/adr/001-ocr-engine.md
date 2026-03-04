# ADR-001: OCR-Engine-Auswahl

## Status
Accepted (ersetzt vorherige Entscheidung für Tesseract)

## Kontext
Die App erkennt Text auf fotografierten Kinderbuchseiten. Anforderungen:
- **Word-Level Bounding Boxes** — jedes Wort braucht eine exakte Position für das Overlay
- **Deutsche Umlaute** (ä, ö, ü, ß) — Kernsprache ist Deutsch
- **Multilingualität** — Englisch, Französisch, Spanisch, Portugiesisch
- **Lokal lauffähig** — kein Cloud-API, kein API-Key
- **CPU-tauglich** — soll auf normaler Hardware laufen

## Bewertete Optionen

### Tesseract 5.x (pytesseract)
- **Word-Level BBoxes:** Ja, via `image_to_data()`
- **Umlaute:** Gut (mit `tesseract-lang` Paket)
- **CPU:** Ja, sehr schnell
- **Schwächen:** Einzelzeichen-Verwechslungen (`!` → `i`, `t` → `r`), benötigt OpenCV-Preprocessing (CLAHE + Otsu), Systemabhängigkeit (`brew install tesseract`)

### docTR mit multilingual PARSeq ✅ Gewählt
- **Word-Level BBoxes:** Ja, nativ (Page → Block → Line → Word)
- **Umlaute:** Perfekt mit `Felix92/doctr-torch-parseq-multilingual-v1`
- **CPU:** Ja (~2-5s pro Seite)
- **Stärken:** Transformer-basierte Erkennung sieht Wörter als Gesamtbild → erkennt `aufregend!,` korrekt; kein Preprocessing nötig; kein System-Package nötig (pure Python/PyTorch)
- **Schwächen:** Größere Dependencies (~400MB PyTorch); erster Start lädt Modelle von HuggingFace; gelegentliche Fehlerkennungen bei dekorativen Schriften

### PaddleOCR v5
- **Word-Level BBoxes:** Ja
- **Umlaute:** Gefixt in v5 mit `latin_PP-OCRv5_mobile_rec` Modell — aber nur dieses Modell, andere Varianten haben den Bug noch
- **CPU:** Ja, sehr leichtgewichtig
- **Schwächen:** Fragile Umlaut-Unterstützung (modellabhängig), PaddlePaddle-Framework weniger verbreitet als PyTorch

### Surya v3
- **Word-Level BBoxes:** Ja (neu seit v3)
- **Umlaute:** Gut (90+ Sprachen)
- **CPU:** Nein — benötigt GPU (~16-20GB VRAM)
- **Schwächen:** Hoher Ressourcenverbrauch, nicht für Consumer-Hardware geeignet

### EasyOCR
- **Word-Level BBoxes:** Nein — nur Segment-Level
- **Umlaute:** OK
- **Schwächen:** Dealbreaker wegen fehlender Word-Level BBoxes; Entwicklung verlangsamt

### GOT-OCR2
- **Word-Level BBoxes:** Nein
- **Umlaute:** Unklar
- **Schwächen:** Vision-Language-Modell ohne strukturierte BBox-Ausgabe; benötigt CUDA-GPU; löst ein anderes Problem

## Entscheidung
**docTR** mit dem multilingualen PARSeq-Modell.

## Vergleichstest auf Kinderbuch-Covern

| Kriterium | Tesseract 5 | docTR (multilingual) |
|---|---|---|
| `aufregend!,` | ✗ `aufregendi,` | ✅ `aufregend!,` |
| `findet` | ✗ `finder` | ✅ `findet` |
| `Waschbär` | ✅ | ✅ |
| `größten` | ✅ | ✅ |
| `überhaupt` | ✅ | ✅ |
| `für` | ✅ | ✅ |
| `Genau` | ✅ | ✗ `Cenau` |
| Noise-Filterung | Wenig Noise | Mehr Noise (Illustrationen) |
| System-Dependency | `brew install tesseract` | Keine |
| Preprocessing nötig | Ja (CLAHE + Otsu) | Nein |

## Konsequenzen
- Kein Tesseract als Systemabhängigkeit mehr — vereinfacht Setup
- Kein OpenCV-Preprocessing nötig — weniger Code
- Kein Spell-Checker nötig — docTR erkennt Interpunktion und Grammatik besser
- PyTorch als Dependency (~400MB) — größerer `pip install`
- Erster Start lädt Modelle von HuggingFace (~200MB) — danach gecached
