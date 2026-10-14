# Architecture and development workflow

## Goals

Format Anything follows a layered Flutter architecture inspired by the maintainability practices used in PoultryInventory. This document records the intended boundaries; it does not claim every layer has already been implemented.

## Flutter layers

- `lib/screens/`: route-level screens and page composition.
- `lib/widgets/`: reusable presentational widgets.
- `lib/providers/`: application and processing state; providers should coordinate work rather than implement parsing.
- `lib/models/`: typed application data models.
- `lib/services/`: formatting, OCR, extraction, API calls, file handling and sharing.
- `lib/repositories/`: persistence abstractions and implementations.
- `lib/core/`: configuration, error types, logging and shared utilities.
- `lib/platform/`: browser and native adapters for capabilities that differ by platform.

The current starter has been incrementally improved by extracting `ResultItem` into `lib/models/result_item.dart` and `Formatter` into `lib/services/formatter_service.dart`. The rest of the UI remains in `lib/main.dart` for now; subsequent changes should move one cohesive feature at a time and preserve behavior.

## Backend boundary

If/when the FastAPI backend is added to this repository, keep it under `backend/` with separate API routes, schemas, processing services, configuration and tests. Do not commit credentials, local model weights, real user documents, or private benchmark artifacts.

## Local-first processing

1. Use deterministic local formatting for supported text formats.
2. Use platform-compatible OCR for image input.
3. Validate structured extraction and expose uncertainty to the user.
4. Call FastAPI or an external AI provider only when local processing is insufficient, network access is available, and the user has permitted cloud processing.
5. Keep API secrets on the server, never in Flutter client code.

## Git workflow

- `main`: stable baseline.
- `develop`: integration branch.
- `feature/*`: isolated, reviewable changes.

Before merging, run `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, and applicable platform builds. Record platform-specific limitations rather than claiming a build passed when it has not been run.

## Migration rule

Avoid mass file moves. For each step: extract one model/service/widget, update imports, add focused tests, inspect the diff, and verify the analyzer. Keep existing OCR benchmarks and experimental prompts separate from production logic until benchmarked.
