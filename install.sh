#!/bin/bash
# ============================================================================
# Local AI Dev Kit - Installer Bootstrap
# スクリプトをダウンロードしてから実行する（パイプ問題の回避）
# ============================================================================

set -e

TMPDIR="${TMPDIR:-/tmp}"
SETUP_FILE="$TMPDIR/local-ai-dev-kit-setup.sh"

echo "Local AI Dev Kit をダウンロード中..."
curl -fsSL "https://raw.githubusercontent.com/ikki-dali/local-ai-dev-kit/main/setup.sh" -o "$SETUP_FILE"
chmod +x "$SETUP_FILE"

echo "セットアップを開始します..."
echo ""
exec bash "$SETUP_FILE"
