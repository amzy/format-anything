# Format Anything — Flutter mobile starter

This project implements a mobile-first UI inspired by the supplied UX specification board: blue/white visual system, home dashboard, quick actions, text editor, processing/result view, receipt OCR, history, settings, copy/share actions and local formatters.

## Run

1. Install Flutter stable and Xcode (iOS) / Android Studio (Android).
2. From this directory run:
   ```sh
   flutter create . --platforms=ios,android
   flutter pub get
   flutter run
   ```
3. For iOS, run `cd ios && pod install && cd ..` if CocoaPods is required by your setup.

## Current implementation

- Text cleanup, JSON pretty-printing, CSV conversion, tracking-parameter removal from URLs, and heuristic receipt JSON output.
- Image picker and camera capture; ML Kit Latin-script OCR runs on-device.
- Local history using SharedPreferences; copy/share via platform actions.
- Responsive Flutter UI for Home, History, Settings, Input Preview, and Formatted Result.

## Important limitations

- This is a functional starter source package, not a signed or release-tested IPA/APK. Flutter was not available in the packaging environment, so it could not be compiled here.
- Native iOS Share Extension / Android share-intent ingestion is not configured by this starter; share-out actions are implemented. Add platform-specific share-in support as a separate integration step.
- OCR currently uses ML Kit Latin recognition. The OCR language selector is intentionally English-only until more scripts are integrated and tested.
- Receipt field extraction is heuristic and explicitly marks generated receipt JSON for review. It is not production-grade financial extraction.
- The `Prefer on-device processing` and `Save history locally` settings are saved as preferences; API fallback is not yet connected. No cloud/API request is made by this starter.
- The supplied design board is included at `assets/ux_specification_board.png` as a reference asset.

## Suggested next integration

Connect this UI to the existing FastAPI endpoint behind a small `ProcessingService` interface, and only invoke the API when local validation fails, the user permits cloud processing, and network access is available. Keep experimental extraction benchmarks and prompts separate from production code until evaluated.
