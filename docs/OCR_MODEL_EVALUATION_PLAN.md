# Format Anything — OCR and Receipt Model Evaluation Plan

## Status
Planning only. No candidate has been benchmarked on a representative labelled dataset. Do not claim a model is tested or production-ready until measurements are recorded.

## Recommended architecture
- Web baseline: Tesseract.js in the browser using WebAssembly. No per-image OCR API fee; browser CPU, memory, language-data download, hosting and bandwidth still have costs.
- Android/iOS baseline: retain existing on-device Google ML Kit.
- Cloud OCR candidate: Google Cloud Vision TEXT_DETECTION for general images or DOCUMENT_TEXT_DETECTION for dense documents.
- Structured receipt extraction candidate: evaluate Gemini with schema validation or Document AI Expense Parser separately.
- Do not train a custom model initially. Benchmark these options first.

## Privacy and security
- Never put service-account keys or privileged secrets in Flutter or web assets.
- Cloud calls must go through an authenticated backend such as Cloud Run or a Firebase HTTPS function.
- Validate authentication, MIME type, image dimensions and size; apply quotas, rate limits, timeouts and retries.
- Ask consent before uploading receipts. Respect local-only mode.
- Avoid logging raw images or receipt text. Define retention/deletion policy.
- Configure budgets and alerts; alerts are not a hard spending cap.

## Benchmark dataset
Build a private, permissioned dataset of at least 200 images: 50 clean printed receipts, 50 skewed phone photos, 30 low-light/blur/glare, 30 faded/thermal receipts, 20 representative multilingual examples, and 20 screenshots/invoices/dense documents. Keep at least 20% as a holdout set. Label full text and visible merchant, date, subtotal, tax, total, currency and line items. Never publish customer receipts.

## Metrics
OCR: character error rate (CER), word error rate (WER), successful-run rate, p50/p95 latency, first-run model download time, memory, and results by image-quality/language category.
Receipt extraction: per-field exact match, numeric amount accuracy, line-item precision/recall, hallucinated-field rate, null accuracy, schema-valid rate, latency and cost per 1,000 receipts.

## Proposed acceptance gates (not measured results)
1. No Android/iOS OCR regression.
2. Browser OCR works on current iOS Safari and desktop Safari/Chrome.
3. At least 95% successful OCR execution on supported image types.
4. Record CER/WER for each candidate before selection.
5. Target >=98% exact total amount on clearly legible test receipts; unreadable values must be null, never guessed.
6. >=99% schema-valid output after validation/retry.
7. Measure p95 latency; initial target <=8 seconds for cloud calls under a representative network.
8. No cloud upload without consent and no credentials in client bundles.
9. Configure cost/quota monitoring before general rollout.

## Test plan
Unit tests: platform routing; empty/unsupported image errors; OCR text reaches formatter once; busy state clears after failures; invalid receipt fields are not invented.
Integration tests: JPEG/PNG, rotated image, blur, no-text image, oversized image, offline state, worker/model download failure, repeated scans, cancellation, and native camera/gallery capture. For cloud: missing auth, size limit, rate limit, timeout, quota exceeded, malformed provider response, outage and local-only mode. Confirm no image or text upload in local-only mode.
Device matrix: iPhone Safari, desktop Safari and Chrome, Android Chrome, and at least one low-memory phone.

## Release procedure
1. Run formatter unit tests, all Flutter tests and flutter analyze.
2. Build web release with flutter build web --release.
3. Manually verify photo OCR and receipt scanning on target browsers/devices.
4. Record dataset version, library/model versions, browser/device, metrics and cost.
5. Roll out behind a feature flag and review errors/spend before broad enablement.

## Deployment choices
Browser OCR: pin Tesseract.js and language data versions; use a persistent worker; lazy-load with progress UI; host the Flutter web build normally. Prefer controlled assets over an unpinned CDN for production and test CSP/offline behavior.

Google Cloud Vision: enable billing and Vision API; call it from an authenticated Cloud Run/Firebase backend using a least-privilege runtime service account. Enforce file limits, auth, quotas, rate limits, timeouts and redacted logs. Return normalized text/layout. Add Gemini or Document AI only if benchmark gains justify extra cost.

Decision rule: start with Tesseract.js on web and ML Kit on native. Compare Vision OCR on the same labelled set. Add a structured model only if it materially improves field-level accuracy. A prompt is not a substitute for evaluation.
