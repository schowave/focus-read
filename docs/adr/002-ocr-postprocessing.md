# ADR-002: OCR-Nachverarbeitung

## Status
Accepted

## Kontext
OCR-Engines liefern neben echtem Text auch Artefakte: Barcode-Fragmente, Verlagslogos, ISBN-Nummern, Illustrationsrauschen. Zusätzlich können einzelne Wörter falsch erkannt werden.

## Bewertete Optionen für Textkorrektur

### Kein Post-Processing
- Einfachste Lösung
- Noise bleibt sichtbar → schlechte UX für Kinder

### pyspellchecker (Rechtschreibprüfung)
- **Getestet:** Korrigiert `aufregendi` → `aufregend`, aber:
  - Kann kontextabhängige Fehler nicht erkennen (`finder` ist ein gültiges Wort)
  - Mangelt Komposita (`Schatzsuche` → `Schatzsucher`) und Namen (`Mono` → `Mond`)
  - Verliert Interpunktion (`aufregend!,` → `aufregend,`)
- **Fazit:** Zu viele Nebenwirkungen für zu wenig Nutzen

### LanguageTool (Grammatikprüfung)
- **Getestet:** Versprach Satzkontext-basierte Korrektur, aber:
  - `aufregendi` → `aufregend` (gleich wie Spell-Checker)
  - `Mono` → `Mond` (Name zerstört)
  - `finder` → `Finder` (nur Großschreibung, nicht `findet`)
  - 253MB Java-Server als Dependency
- **Fazit:** Kein Mehrwert gegenüber Spell-Checker, schwerere Dependency

### LLM-basierte Korrektur (z.B. Claude API)
- Würde kontextabhängige Fehler lösen
- Benötigt API-Key und Internetverbindung
- Kosten pro Anfrage
- Overkill wenn die OCR-Engine selbst besser wird

### Noise-Filter ✅ Gewählt
- Regelbasierter Filter, der Nicht-Wort-Artefakte entfernt
- Kein Versuch, erkannte Wörter zu "verbessern" (das macht die OCR-Engine)

## Entscheidung
**Nur Noise-Filter, keine Textkorrektur.** Der Wechsel zu docTR (ADR-001) hat die Textkorrektur-Probleme an der Wurzel gelöst. Der Noise-Filter entfernt:
- Einzelne Nicht-Buchstaben-Zeichen
- Reine Zahlen (Barcodes)
- Zahl-Buchstaben-Mischungen (`44674_`)
- Text mit Klammern (OCR-Artefakte)
- URLs/Domains (Verlagswebsites)
- Low-Confidence-Erkennungen (< 85%)

## Konsequenzen
- Keine zusätzlichen Dependencies (pyspellchecker, LanguageTool)
- Einfacher, deterministischer Code (~20 Zeilen)
- Korrekturen passieren in der OCR-Engine selbst, nicht im Post-Processing
- Lerneffekt: Besser die richtige Engine wählen als eine schlechte Engine mit Post-Processing zu flicken
