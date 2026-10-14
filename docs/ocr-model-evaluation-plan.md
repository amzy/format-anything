# OCR Model Evaluation Plan

## Goal
Make **Scan receipt** and **From photo** work in Flutter Web without breaking native Android/iOS OCR.

## Recommended first implementation
Use **Google Cloud Vision API** with `DOCUMENT_TEXT_DETECTION` for receipts/documents and `TEXT_DETECTION` for general photos. It is a managed OCR API, not a model that we need to train or host. Keep Google ML Kit for native Android/iOS.

Do not call Cloud Vision directly from Flutter Web with an API key: browser bundles are public, so the key can be copied and abused. Put Vision behind an authenticated HTTPS backend (Cloud Run or Cloud Functions 2nd gen), enforce Firebase Authentication/App Check or equivalent request verification, validate image size/type, rate-limit users, and store secrets in Secret Manager. Do not log uploaded image bytes or OCR text by default.

## Candidate approaches to benchmark
1. **Google Cloud Vision** — recommended baseline for receipts and general image text.
2. **Tesseract.js in the browser** — useful privacy/offline-ish fallback with no per-image cloud API fee, but benchmark accuracy and latency on low-quality receipts and iPhone photos.
3. **Google ML Kit** — keep for native mobile. It is not available in the browser, which caused the current MissingPluginException.

## Test corpus
Build a small, consented test set before release:
- 30 clean printed receipts, 20 skewed/low-light receipts, 20 screenshots/photos with mixed text, and 10 images with small fonts or tables.
- Include representative English and Hindi images only if those languages are in product scope.
- For every image, create a manually verified ground-truth transcription.
- Do not include real customer documents or sensitive personal/financial data unless consent and retention rules are documented.

## Metrics and acceptance gates
Measure each candidate on the same corpus:
- Character error rate (CER) and word error rate (WER) against ground truth.
- Receipt field accuracy for date, merchant, subtotal, tax, and total where present.
- Median and p95 end-to-end latency on real iPhone Safari over Wi-Fi/mobile network.
- Failure rate, image upload size, and cost per 1,000 images.
- Privacy: whether bytes leave the device, retention, logging, and data region.

Proposed release gates (adjust after baseline): >=95% exact extraction success on clean printed receipts; >=90% correctly extracted total amount when present; <2% request failures; p95 latency under 5 seconds for typical images. Report actual measured results—never claim the model passed until tests run.

## Prompt for an OCR evaluation/implementation model
Use this prompt with a coding model that can inspect the repository:

> You are a senior Flutter, Firebase, and Google Cloud engineer. Inspect the existing Format Anything repository and its current branch before editing. The current app uses `google_mlkit_text_recognition` and fails in iPhone Safari with `MissingPluginException: No implementation found for method vision#startTextRecognizer`. Implement a platform-aware OCR abstraction: preserve the existing ML Kit path for Android/iOS; route Flutter Web image OCR to an authenticated backend using Google Cloud Vision; never put Google credentials/API keys in Flutter/web source. Prefer `DOCUMENT_TEXT_DETECTION` for receipts and `TEXT_DETECTION` for general photos. Preserve current UX, formatting/history flow, and image quality. Add request validation, safe error messages, timeout handling, size/type limits, tests for adapter selection, response parsing, failures, and configuration missing. Add a deployable backend (Cloud Run or Functions 2nd gen) with least-privilege IAM, Secret Manager for secrets, Firebase Authentication/App Check or a documented equivalent, CORS restricted to the deployed app origins, rate limits, and no image/text logging. Add deployment instructions, rollback instructions, cost guardrails, and a test matrix. Do not deploy or incur billable resources without explicit approval. Do not claim tests ran unless they actually ran. Make small commits on `feature/project-structure`; do not merge the PR. First provide an implementation plan and identify any missing credentials/configuration; then implement and test incrementally.

> Model selection rule: do not fine-tune/train a custom model unless the benchmark proves managed OCR insufficient. Run the same ground-truth corpus against Cloud Vision and Tesseract.js and choose using CER/WER, receipt-field accuracy, p95 latency, privacy, and cost.

## Rollout phases
1. **Baseline and architecture** — document the corpus, record current native behavior, add platform OCR interface.
2. **Backend prototype** — implement authenticated Cloud Run/Functions endpoint, request validation and Vision response mapping.
3. **Flutter integration** — keep ML Kit native; web adapter calls backend; display useful errors and preserve formatting flow.
4. **Model bake-off** — run the corpus against Vision and Tesseract.js; save anonymized aggregate metrics.
5. **Security and cost controls** — rate limits, budgets/alerts, quotas, CORS, request size cap, no sensitive logs.
6. **Staging test** — deploy to a non-production project/service and test on iPhone Safari, Android Chrome, Android native, and iOS native.
7. **Production release** — only after acceptance gates pass; gradual rollout and rollback documented.

## Test matrix
| Platform | Scan receipt | From photo | Expected path |
|---|---|---|---|
| iPhone Safari | Pass | Pass | Authenticated Cloud Vision backend |
| Android Chrome | Pass | Pass | Authenticated Cloud Vision backend |
| Android app | Pass | Pass | Google ML Kit |
| iOS app | Pass | Pass | Google ML Kit |
| Web backend unavailable | Friendly error | Friendly error | No uncaught plugin exception |
| Oversized/invalid image | Clear validation error | Clear validation error | Request rejected before OCR |

## Deployment decision
Start with Cloud Vision API behind a small Cloud Run service in a supported nearby region. Do not deploy a custom OCR model to Vertex AI initially. Vertex AI custom endpoints are for cases where an evaluated custom model is necessary and can create always-on compute costs. Firebase Hosting serves the Flutter web app; it does not host the OCR model itself.
