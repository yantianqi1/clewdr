#!/usr/bin/env bash
# Push current changes to GitHub, wait for GHCR build, then pull & restart compose.
set -euo pipefail

BRANCH="${BRANCH:-master}"
IMAGE="ghcr.io/yantianqi1/clewdr:${BRANCH}"
MSG="${1:-deploy: $(date +%Y-%m-%d_%H:%M:%S)}"

cd "$(dirname "$0")"

# 1. Commit & push if there are changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  git commit -m "$MSG"
fi
git push origin "$BRANCH"

# 2. Wait for the GitHub Actions run to finish
if command -v gh >/dev/null 2>&1; then
  echo ">> Waiting for GitHub Actions build..."
  sleep 5
  RUN_ID=$(gh run list --workflow=docker-build.yml --branch "$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId')
  gh run watch "$RUN_ID" --exit-status
else
  echo ">> gh CLI not found. Please wait for the Actions build to finish, then press Enter."
  read -r
fi

# 3. Pull new image and restart
docker compose pull
docker compose up -d
docker image prune -f

echo ">> Deployed $IMAGE"
