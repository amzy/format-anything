# Google Cloud OCR: cost and deployment notes

**Pricing checked:** 14 October 2026. Google prices can change; verify the linked pricing pages before production deployment. Estimates below are in USD and exclude tax, currency conversion, network egress, backend compute, logging, and any other enabled APIs.

## Option A — Cloud Vision API (recommended baseline)
Official pricing: https://cloud.google.com/vision/pricing

For Text Detection and Document Text Detection, Google lists the first **1,000 units per month free**, then **$1.50 per 1,000 units** from 1,001 to 5,000,000 units; the higher-volume tier is listed at $0.60 per 1,000. A unit is one image per feature request. A multipage PDF is billed per page. For one OCR feature on each image, rough API-only cost is:

| Images/month | Approx. OCR API cost |
|---:|---:|
| 500 | $0 |
| 1,000 | $0 |
| 5,000 | $6.00 |
| 10,000 | $13.50 |
| 50,000 | $73.50 |
| 100,000 | $148.50 |

These examples apply the 1,000 free units and $1.50/1,000 tier; confirm the current invoice calculator and exact feature SKU. If you call both TEXT_DETECTION and DOCUMENT_TEXT_DETECTION for the same image, assume two billable feature units unless the pricing rules for your chosen request indicate otherwise. Prefer choosing one mode per image.

Official OCR docs: https://docs.cloud.google.com/vision/docs/ocr

## Option B — Cloud Run proxy
Official pricing: https://cloud.google.com/run/pricing

Cloud Run adds compute/request charges for the backend, beyond Vision API usage. A lightweight proxy with request-based billing and scale-to-zero can be low-cost at modest traffic, but there is no honest single monthly number without region, memory/CPU, request duration, concurrency, min instances, and traffic. Keep minimum instances at zero initially, use request-based billing, cap image sizes, set quotas/budget alerts, and test cold-start latency. Cloud Run has a free tier subject to region and account aggregation; check the calculator before deployment.

For rough sizing, measure actual request duration in staging and enter request count, CPU, memory, and region in the Cloud Run pricing calculator: https://cloud.google.com/products/calculator

## Option C — deploy a custom OCR model on Vertex AI
Usually **not recommended for the first release**. Vertex AI model endpoints charge for deployment compute while provisioned; the model may need dedicated CPU/GPU resources even when request volume is low. Use this only if the benchmark demonstrates that Vision/Tesseract.js cannot meet a concrete requirement. Official Model Garden deployment pricing overview: https://cloud.google.com/vertex-ai/generative-ai/docs/model-garden/explore-models

## Architecture and security
Flutter Web -> authenticated HTTPS Cloud Run/Functions endpoint -> Cloud Vision API -> return extracted text -> existing formatter flow.

- Never embed a service-account key or unrestricted Cloud Vision API key in Flutter/web assets.
- Use a service identity with minimum permissions; store secrets in Secret Manager if a secret is required.
- Verify Firebase ID tokens on the backend and add App Check where appropriate; App Check alone should not be treated as user authentication.
- Restrict CORS to production/staging origins, set upload size/type limits, request timeouts, and per-user rate limits.
- Do not log image payloads, OCR text, access tokens, or receipt contents.
- Set Cloud Billing budgets and alerts. Budgets alert; they do not automatically cap spend.
- Use a staging project/service first. Do not deploy billable resources until the owner explicitly approves.

## Before production cost approval
Record expected monthly images, average image size, chosen OCR feature, backend region, p50/p95 duration, and desired budget cap. Recalculate using the Google Cloud calculator and inspect billing after a staged load test.
