#!/usr/bin/env bash
# run-lighthouse.sh — Runs Lighthouse audit against a URL
# Usage: ./run-lighthouse.sh <URL> [output-directory]
# Requires: npm install -g lighthouse (or npx)
set -euo pipefail

URL="${1:-}"
OUTPUT_DIR="${2:-./lighthouse-reports}"

if [ -z "$URL" ]; then
  echo "Usage: $0 <URL> [output-directory]"
  echo "Example: $0 https://myapp.com ./reports"
  exit 1
fi

# Check if lighthouse is available
if ! command -v lighthouse &>/dev/null; then
  echo "Lighthouse not found. Install with: npm install -g lighthouse"
  echo "Or run with npx: npx lighthouse $URL"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_NAME="lighthouse_${TIMESTAMP}"

echo "=== Lighthouse Audit ==="
echo "URL: $URL"
echo "Output: $OUTPUT_DIR/$REPORT_NAME"
echo ""

# Run Lighthouse with performance-focused settings
lighthouse "$URL" \
  --output=html,json \
  --output-path="$OUTPUT_DIR/$REPORT_NAME" \
  --chrome-flags="--headless --no-sandbox" \
  --only-categories=performance,accessibility,best-practices,seo \
  --throttling-method=simulate \
  --preset=desktop \
  --quiet

echo ""
echo "=== Results ==="

# Extract scores from JSON report
if [ -f "$OUTPUT_DIR/${REPORT_NAME}.report.json" ]; then
  PERF=$(python3 -c "
import json
with open('$OUTPUT_DIR/${REPORT_NAME}.report.json') as f:
    data = json.load(f)
    cats = data['categories']
    print(f\"Performance:    {int(cats['performance']['score']*100)}/100\")
    print(f\"Accessibility:  {int(cats['accessibility']['score']*100)}/100\")
    print(f\"Best Practices: {int(cats['best-practices']['score']*100)}/100\")
    print(f\"SEO:            {int(cats['seo']['score']*100)}/100\")
    audits = data['audits']
    print()
    print('Core Web Vitals:')
    if 'largest-contentful-paint' in audits:
        lcp = audits['largest-contentful-paint']['numericValue']/1000
        print(f\"  LCP: {lcp:.1f}s {'(good)' if lcp < 2.5 else '(needs improvement)' if lcp < 4 else '(poor)'}\")
    if 'cumulative-layout-shift' in audits:
        cls = audits['cumulative-layout-shift']['numericValue']
        print(f\"  CLS: {cls:.3f} {'(good)' if cls < 0.1 else '(needs improvement)' if cls < 0.25 else '(poor)'}\")
    if 'total-blocking-time' in audits:
        tbt = audits['total-blocking-time']['numericValue']
        print(f\"  TBT: {tbt:.0f}ms {'(good)' if tbt < 200 else '(needs improvement)' if tbt < 600 else '(poor)'}\")
" 2>/dev/null || echo "(Install python3 to see parsed results)")
  echo "$PERF"
fi

echo ""
echo "HTML Report: $OUTPUT_DIR/${REPORT_NAME}.report.html"
echo "JSON Report: $OUTPUT_DIR/${REPORT_NAME}.report.json"
echo ""
echo "=== Audit Complete ==="
