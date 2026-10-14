# Google Cloud OCR — Cost and Deployment Notes

Prices depend on product/SKU, region, currency and current pricing. Verify the official pricing pages and Google Cloud Pricing Calculator immediately before launch. Figures below are illustrative, not a quote.

## Options
- Tesseract.js browser OCR: no per-image OCR API charge; users' devices do the work, but hosting, bandwidth, model downloads and device performance still matter.
- Cloud Vision OCR: managed text extraction; charged by the applicable feature and billable units after any applicable free allowance.
- Document AI Expense Parser: specialized expense/receipt field extraction; official pricing currently lists $0.10 per count in the standard column, where one count covers up to 10 pages. Confirm processor and free-tier eligibility on the live pricing page.
- Gemini via Vertex AI: token/model-based pricing for interpreting OCR text or images and producing structured fields. Evaluate separately and validate outputs.
- Cloud Run: usage-based backend cost for CPU, memory, requests and networking, plus build/artifact costs.

## Official sources
- Vision OCR guide: https://cloud.google.com/vision/docs/ocr
- Vision pricing: https://cloud.google.com/vision/pricing
- Document AI pricing: https://cloud.google.com/document-ai/pricing
- Cloud Run pricing: https://cloud.google.com/run/pricing
- Pricing calculator: https://cloud.google.com/products/calculator

## Example OCR budget math
Use the current applicable unit price and free allowance from the Vision pricing page. Formula: billable requests = max(0, monthly requests - applicable free allowance); estimate = billable requests × current per-request price. For illustration only, at an assumed $1.50 per 1,000 billable images: 1,000 images = $1.50; 10,000 = $15; 100,000 = $150. This is not a guaranteed price for every Vision OCR feature/region. Multiple features, pages, retries, and other services may change cost.

## Cloud Run cost controls
The published Cloud Run pricing page describes a free tier for eligible request-based usage, including CPU-seconds, GiB-seconds and requests. Actual spend depends on region, CPU/memory, duration, concurrency, cold starts, min instances, networking, Cloud Build and Artifact Registry. Avoid minimum instances unless latency requires them. Set max instances, request size/time limits, quotas and budget alerts; budget alerts do not automatically stop spending.

## Before launch, estimate
Images/month, OCR requests/image, average image size and latency, fraction requiring structured extraction, model input/output tokens, retry rate, Cloud Run settings, storage/egress, and applicable free-tier/pricing.

## Recommended staged rollout
1. Use local browser OCR and native ML Kit by default.
2. Call Vision only when user consents to cloud fallback or requests it.
3. Run a structured model only when structured receipt fields are needed.
4. Reuse OCR output across formatting actions; do not rerun OCR just to change output format.
5. Monitor cost per 1,000 images and apply per-user quotas.

## Deployment outline
1. Select/create a Google Cloud project and configure billing.
2. Enable Cloud Vision API.
3. Deploy an authenticated HTTPS backend on Cloud Run or a Firebase HTTPS function.
4. Use a least-privilege runtime service account. Never put service-account JSON or privileged keys in Flutter/web assets.
5. Enforce auth, size limits, rate limits, timeouts, quotas and safe logging.
6. Return normalized text/layout. Keep receipt field extraction as a separate optional endpoint.
7. Configure monitoring, budgets and alerts; test abuse and spending limits before production.

## Repository note
This branch currently has no web/ folder, and README describes a future backend integration rather than a confirmed deployed API. Confirm the actual deployment target before choosing Cloud Run versus Firebase Functions. No model has been trained, deployed or benchmarked by these notes.
