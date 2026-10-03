#!/usr/bin/env bash
# discord-notify.sh — post one "PR opened" message to the team Discord channel.
# Used by /ship after the PR is created. The message links to GitHub, where the PR is reviewed and
# merged; there are no follow-up posts.
#
# Usage: discord-notify.sh <pr-url> <pr-title> [one-line summary]
#
# Reads the webhook from DISCORD_WEBHOOK_URL (a Codespaces secret or a local env var). Never commit
# the URL or print it: anyone holding it can post to the channel.
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: $0 <pr-url> <pr-title> [summary]" >&2
  exit 64
fi
if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
  echo "DISCORD_WEBHOOK_URL is not set; skipped the Discord post." >&2
  exit 3
fi

url="$1" title="$2" summary="${3:-}"
branch="$(git branch --show-current 2>/dev/null || true)"
author="$(git config user.name 2>/dev/null || true)"

payload="$(jq -n --arg url "$url" --arg title "$title" --arg summary "$summary" \
  --arg branch "$branch" --arg author "$author" '{
    username: "ship",
    allowed_mentions: { parse: [] },
    embeds: [{
      title: ("PR opened: " + $title)[0:256],
      url: $url,
      description: ([$summary, "Review and merge on GitHub: " + $url] | map(select(. != "")) | join("\n\n"))[0:4096],
      color: 2600544,
      fields: ([
        (if $branch != "" then { name: "Branch", value: ("`" + $branch + "` → `stable`"), inline: true } else empty end),
        (if $author != "" then { name: "Author", value: $author, inline: true } else empty end)
      ])
    }]
  }')"

# ?wait=true makes Discord return the created message, so a failure is an HTTP error, not silence.
if ! out="$(curl -sS --fail-with-body -X POST -H 'Content-Type: application/json' \
  --data "$payload" "${DISCORD_WEBHOOK_URL}?wait=true" 2>&1)"; then
  # Print Discord's error body only; the webhook URL never appears in it.
  echo "Discord post failed: $(printf '%s' "$out" | sed 's#https://discord[^ ]*#<webhook>#g' | head -c 300)" >&2
  exit 1
fi
echo "Posted to Discord."
