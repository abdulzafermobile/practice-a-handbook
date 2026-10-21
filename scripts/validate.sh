#!/usr/bin/env bash
# Fails the build if the site is not fit to publish.
set -euo pipefail

DIR="${1:-public}"     # folder to check; defaults to public
errors=0

# 1. Required files exist
for f in index.html styles.css; do
  [ -f "$DIR/$f" ] || { echo "MISSING: $DIR/$f"; errors=$((errors+1)); }
done

for page in "$DIR"/*.html; do
  # 2. Every page has a <title>
  grep -q '<title>' "$page" || { echo "NO <title>: $page"; errors=$((errors+1)); }

  # 3. No unfinished work is published
  if grep -n 'TODO' "$page"; then
    echo "TODO left in: $page"; errors=$((errors+1))
  fi

  # 4. Every local link like href="runbooks.html" points at a file that exists
  for link in $(grep -o 'href="[^"#:]*\.html"' "$page" | sed 's/href="//; s/"$//'); do
    [ -f "$DIR/$link" ] || { echo "BROKEN LINK in $page -> $link"; errors=$((errors+1)); }
  done
done

if [ "$errors" -gt 0 ]; then
  echo "Validation FAILED with $errors problem(s)"
  exit 1
fi
echo "Validation passed"
