#!/usr/bin/env bash
# Records the commits in this push at the top of the changelog file.
set -euo pipefail

FILE="${CL_FILE:-CHANGELOG.md}"
TITLE="${CL_TITLE:-Changelog}"
MESSAGE="${CL_MESSAGE:-Update CHANGELOG}"
BRANCH="${CL_BRANCH:?branch name missing}"
AFTER="${CL_AFTER:?commit sha missing}"
BEFORE="${CL_BEFORE:-}"
ACTOR="${CL_ACTOR:-unknown}"
ZERO=0000000000000000000000000000000000000000
out() { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1" >> "$GITHUB_OUTPUT" || true; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "::error::Run actions/checkout first (with fetch-depth: 0)."; exit 1
fi
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  git fetch --quiet --unshallow || echo "::warning::Shallow clone: use actions/checkout with fetch-depth: 0 for complete entries."
fi

# Which commits this push added. New branches and force pushes fall back to the latest commit.
if [ -z "$BEFORE" ] || [ "$BEFORE" = "$ZERO" ] || ! git cat-file -e "$BEFORE^{commit}" 2>/dev/null; then
  RANGE="$AFTER -1"; NOTE=" (new branch or rewritten history: latest commit only)"
else
  RANGE="$BEFORE..$AFTER"; NOTE=""
fi

ENTRIES=""
COUNT=0
# shellcheck disable=SC2086
while IFS=$'\t' read -r sha date author subject; do
  [ -z "$sha" ] && continue
  [ "$subject" = "$MESSAGE" ] && continue
  line="- $date  $author  \`${sha:0:7}\`  $subject"
  if [[ "$subject" == "Update from Shopify for theme"* ]]; then
    files=$(git diff-tree --no-commit-id --name-only -r "$sha")
    if [ "${CL_SKIP_SETTINGS:-false}" = "true" ] && [ "$files" = "config/settings_data.json" ]; then
      continue
    fi
    if [ "${CL_LABEL_EDITOR:-true}" = "true" ]; then
      n=$(printf '%s\n' "$files" | grep -c . || true)
      shown=$(printf '%s\n' "$files" | head -n 5 | sed 's/^/`/; s/$/`/' | paste -sd ',' - | sed 's/,/, /g')
      [ "$n" -gt 5 ] && shown="$shown and $((n - 5)) more"
      line="- $date  **Theme editor**  \`${sha:0:7}\`  changed $shown"
    fi
  fi
  ENTRIES+="$line"$'\n'
  COUNT=$((COUNT + 1))
done < <(git log --no-merges --date=format:'%Y-%m-%d %H:%M' --format=$'%H\t%ad\t%an\t%s' $RANGE)

out "entries=$COUNT"
if [ "$COUNT" -eq 0 ]; then echo "Nothing to record."; exit 0; fi

mkdir -p "$(dirname "$FILE")"
STAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
HEADER="# $TITLE"$'\n\n'"Every push is recorded here automatically: when, which branch, who pushed, and each commit."$'\n'
{
  printf '%s\n' "$HEADER"
  printf '## %s - `%s` - pushed by %s%s\n\n' "$STAMP" "$BRANCH" "$ACTOR" "$NOTE"
  printf '%s' "$ENTRIES"
  if [ -f "$FILE" ]; then
    echo
    # keep the old entries, without the old header
    awk 'found || /^## /{found=1; print}' "$FILE"
  fi
} > "$FILE.new"
mv "$FILE.new" "$FILE"
echo "Recorded $COUNT commit(s) in $FILE."

[ "${CL_PUSH:-true}" = "true" ] || exit 0
git add "$FILE"
git diff --cached --quiet && exit 0
git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit --quiet -m "$MESSAGE"
# another push may land first; rebase and retry a few times
for i in 1 2 3; do
  if git push --quiet origin "HEAD:refs/heads/$BRANCH"; then echo "Pushed."; exit 0; fi
  echo "Push rejected, retrying ($i)."
  git pull --quiet --rebase origin "$BRANCH"
done
echo "::error::Couldn't push the changelog after 3 tries."; exit 1
