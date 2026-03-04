# ADR-002: OCR Post-Processing

## Status
Accepted

## Context
OCR engines produce artifacts alongside real text: barcode fragments, publisher logos, ISBN numbers, illustration noise. Additionally, individual words may be misrecognized.

## Considered Options for Text Correction

### No post-processing
- Simplest solution
- Noise remains visible → poor UX for children

### pyspellchecker (spell checking)
- **Tested:** Corrects `aufregendi` → `aufregend`, but:
  - Cannot detect context-dependent errors (`finder` is a valid word)
  - Mangles compound words (`Schatzsuche` → `Schatzsucher`) and names (`Mono` → `Mond`)
  - Loses punctuation (`aufregend!,` → `aufregend,`)
- **Verdict:** Too many side effects for too little benefit

### LanguageTool (grammar checking)
- **Tested:** Promised sentence-context correction, but:
  - `aufregendi` → `aufregend` (same as spell-checker)
  - `Mono` → `Mond` (name destroyed)
  - `finder` → `Finder` (only capitalization, not `findet`)
  - 253MB Java server as dependency
- **Verdict:** No improvement over spell-checker, heavier dependency

### LLM-based correction (e.g. Claude API)
- Would solve context-dependent errors
- Requires API key and internet connection
- Cost per request
- Overkill when the OCR engine itself can be improved

### Noise filter ✅ Chosen
- Rule-based filter that removes non-word artifacts
- No attempt to "improve" recognized words (that's the OCR engine's job)

## Decision
**Noise filter only, no text correction.** Switching to docTR (ADR-001) solved the text correction problems at the root. The noise filter removes:
- Single non-letter characters
- Pure numbers (barcodes)
- Digit-letter mixtures (`44674_`)
- Text with parentheses/brackets (OCR artifacts)
- URLs/domains (publisher websites)
- Low-confidence recognitions (< 85%)

## Consequences
- No additional dependencies (pyspellchecker, LanguageTool)
- Simple, deterministic code (~20 lines)
- Corrections happen in the OCR engine itself, not in post-processing
- Lesson learned: better to choose the right engine than to patch a weak engine with post-processing
