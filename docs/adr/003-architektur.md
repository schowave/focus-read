# ADR-003: Anwendungsarchitektur

## Status
Accepted

## Kontext
Die App soll auf Tablets/Phones von Kindern genutzt werden: Buchseite fotografieren, Wörter einzeln hervorheben, vorlesen.

## Bewertete Optionen

### Native App (iOS/Android)
- Beste Kamera-Integration und Performance
- Zwei Codebases oder React Native/Flutter
- App-Store-Deployment nötig
- Overkill für den Anwendungsfall

### Electron/Desktop-App
- Kein Kamerazugang auf Tablets
- Nicht für den Anwendungsfall geeignet

### Python-Backend + Web-Frontend ✅ Gewählt
- **Backend:** FastAPI — minimaler HTTP-Server, statische Dateien, ein OCR-Endpoint
- **Frontend:** Vanilla HTML/JS/CSS — kein Build-Step, kein Framework
- **Kamera:** `<input type="file" capture="environment">` — nutzt die native Kamera-App des Geräts
- **TTS:** Web Speech API (`speechSynthesis`) — im Browser eingebaut, keine Dependency

## Entscheidung
**FastAPI + Vanilla-Frontend.** Minimale Architektur:

```
[Browser] → Foto aufnehmen → POST /api/ocr → [FastAPI + docTR]
[Browser] ← JSON (words + bboxes) ← [FastAPI]
[Browser] → Wörter als Overlays anzeigen → Tap navigiert → TTS spricht vor
```

## Konsequenzen
- Ein einziger `make run` startet alles
- Funktioniert auf jedem Gerät im selben Netzwerk
- Kein Build-Step, kein npm, kein Bundler
- OCR läuft auf dem Server (CPU-intensiv) — nicht auf dem Tablet
- TTS läuft im Browser — keine Server-Abhängigkeit für Audio
