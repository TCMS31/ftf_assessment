#!/usr/bin/env bash
# Regenerates docs/output/api-transcript.txt and docs/output/cache-timing.txt.
#
# Usage:  bin/rails server -p 8710 &   # in another shell
#         docs/capture_api.sh
#
# Everything quoted in the README comes from this script; nothing is hand-written.
set -uo pipefail

HOST="${HOST:-http://127.0.0.1:8710}"
OUT="$(cd "$(dirname "$0")" && pwd)/output"
NOISE='^(x-runtime|etag|date|x-request-id|server|vary|referrer|cache-control|x-permitted|x-xss|x-content|x-download|x-frame|transfer-encoding|connection|content-length)'

api() { curl -sS -i -X POST "$HOST/api/v1/encryptions/rot13" -H 'Content-Type: application/json' "$@" | grep -viE "$NOISE"; }

{
  echo "# Captured API transcript"
  echo "# Regenerate with: docs/capture_api.sh   (app on $HOST)"
  echo "# Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo

  echo '$ curl -i -X POST $HOST/api/v1/encryptions/rot13 -d {"original_string":"Hello, World!"}'
  api -d '{"original_string":"Hello, World!"}'
  echo

  echo '$ ... -d {}                            # original_string absent'
  api -d '{}'
  echo

  echo '$ ... -d {"original_string":12345}     # non-string: refused, nothing internal leaked'
  api -d '{"original_string":12345}'
  echo

  echo '$ ... --data-binary ""                 # empty body'
  api --data-binary ''
  echo

  echo '$ ... -d {not json                     # malformed body'
  api -d '{not json'
  echo

  echo '$ curl $HOST/wiki/Pig_Latin.json       # first paragraph, original and translated'
  curl -sS "$HOST/wiki/Pig_Latin.json" | python3 -c \
    "import sys,json;d=json.load(sys.stdin);print(json.dumps({'error_message':d['error_message'],'original':d['original_paragraphs'][0],'translated':d['translated_paragraphs'][0]},indent=2,ensure_ascii=False))"
  echo

  echo '$ curl -o /dev/null -w "%{http_code}" $HOST/wiki/No_Such_Article_ZZZ_999.json   # upstream 404 -> 502'
  curl -sS -o /dev/null -w '%{http_code}\n' "$HOST/wiki/No_Such_Article_ZZZ_999.json"
  echo

  echo "\$ curl -o /dev/null -w '%{http_code} %{content_type}' \"\$HOST/wiki?wiki_url=Rock+%27n%27+roll\"   # title with spaces and quotes"
  curl -sS -o /dev/null -w '%{http_code} %{content_type}\n' "$HOST/wiki?wiki_url=Rock+%27n%27+roll"
} > "$OUT/api-transcript.txt" 2>&1

{
  echo "# Wikipedia article cache: cold vs warm"
  echo "# Regenerate with: docs/capture_api.sh after restarting the server (the cache is in-process)."
  echo "# Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo
  printf '%-10s %10s %10s\n' 'request' 'bytes' 'seconds'
  for i in 1 2 3 4 5; do
    printf '%-10s %10s %10s\n' "#$i" \
      $(curl -sS -o /dev/null -w '%{size_download} %{time_total}' "$HOST/wiki/Ruby_(programming_language)")
  done
  echo
  echo '# Request #1 is a cold cache: HTTPS round trip to en.wikipedia.org, HTML parse,'
  echo '# then a word-by-word translation of the whole article. #2 onward are cache hits.'
} > "$OUT/cache-timing.txt" 2>&1

echo "wrote $OUT/api-transcript.txt and $OUT/cache-timing.txt"
