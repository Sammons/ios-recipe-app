#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

REMOTE_USER="${REMOTE_USER:-benjaminsammons}"
REMOTE_HOST="${REMOTE_HOST:-mini-unknown.lan}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
SSH_OPTS="-o IdentitiesOnly=yes -i $SSH_KEY -o ConnectTimeout=10"
REMOTE_DIR="${REMOTE_DIR:-builds/$PROJECT_NAME}"

echo "==> Syncing $PROJECT_NAME to $REMOTE_USER@$REMOTE_HOST:~/$REMOTE_DIR"
rsync -az --delete \
  --exclude='.build/' \
  --exclude='.git/' \
  --exclude='.swiftpm/' \
  --exclude='xtool/' \
  --exclude='.DS_Store' \
  -e "ssh $SSH_OPTS" \
  "$PROJECT_DIR/" \
  "$REMOTE_USER@$REMOTE_HOST:~/$REMOTE_DIR/"

echo "==> Running stable tests on remote host"
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "bash -lc '
set -euo pipefail
cd ~/$REMOTE_DIR
~/bin/xcodegen generate >/dev/null
swift package resolve >/dev/null
./ci/run-stable-tests.sh
'"

echo "==> Remote stable tests complete"
