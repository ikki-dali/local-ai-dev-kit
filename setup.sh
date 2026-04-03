#!/bin/bash
# ============================================================================
# Local AI Dev Kit - セキュアなローカルAI開発環境セットアップ
# by Cradle Inc. (crdl.co.jp)
#
# データは一切外部に送信されません。全てローカルで完結します。
# ============================================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  Local AI Dev Kit${NC}"
echo -e "${BOLD}  Secure Local AI Development Environment${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo "  - データは一切外部に送信されません"
echo "  - インターネット接続なしで動作します"
echo "  - 商用利用可能（Apache 2.0ライセンス）"
echo ""

# --- OS Check ---
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}Error: macOS専用です。${NC}"
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo -e "${RED}Error: Apple Silicon (M1/M2/M3/M4/M5) Macが必要です。${NC}"
  exit 1
fi

# --- Memory Check ---
TOTAL_MEM_GB=$(( $(sysctl -n hw.memorysize) / 1024 / 1024 / 1024 ))
echo -e "${BOLD}System: Apple Silicon Mac / ${TOTAL_MEM_GB}GB RAM${NC}"
echo ""

if [[ $TOTAL_MEM_GB -lt 16 ]]; then
  echo -e "${RED}Error: 最低16GB RAMが必要です。${NC}"
  exit 1
fi

# --- Step 1: Homebrew ---
echo -e "${BOLD}[1/4] Homebrewの確認...${NC}"
if ! command -v brew &> /dev/null; then
  echo "Homebrewをインストールします..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo -e "${GREEN}  OK - Homebrew installed${NC}"
fi

# --- Step 2: Ollama ---
echo ""
echo -e "${BOLD}[2/4] Ollamaのインストール...${NC}"
if ! command -v ollama &> /dev/null; then
  brew install ollama
  echo -e "${GREEN}  OK - Ollama installed${NC}"
else
  echo -e "${GREEN}  OK - Ollama already installed${NC}"
fi

# Start ollama server
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
  echo "  Ollamaサーバーを起動します..."
  brew services start ollama 2>/dev/null || ollama serve &>/dev/null &
  sleep 3
fi

# --- Step 3: Models ---
echo ""
echo -e "${BOLD}[3/4] AIモデルのダウンロード...${NC}"
echo ""

if [[ $TOTAL_MEM_GB -ge 24 ]]; then
  echo "  メモリ ${TOTAL_MEM_GB}GB: フルモデル + 軽量モデルをインストール"
  echo ""
  echo -e "  ${YELLOW}Gemma 4 26B (高性能モデル)をダウンロード中...${NC}"
  echo "  ※ 約17GB - 回線速度により数分〜数十分かかります"
  ollama pull gemma4:26b
  echo -e "${GREEN}  OK - gemma4:26b${NC}"
  echo ""
  echo -e "  ${YELLOW}Gemma 4 E4B (軽量モデル)をダウンロード中...${NC}"
  ollama pull gemma4:e4b
  echo -e "${GREEN}  OK - gemma4:e4b${NC}"
elif [[ $TOTAL_MEM_GB -ge 20 ]]; then
  echo "  メモリ ${TOTAL_MEM_GB}GB: 中量モデルをインストール"
  echo ""
  echo -e "  ${YELLOW}Gemma 4 E4B (中量モデル)をダウンロード中...${NC}"
  ollama pull gemma4:e4b
  echo -e "${GREEN}  OK - gemma4:e4b${NC}"
elif [[ $TOTAL_MEM_GB -ge 16 ]]; then
  echo "  メモリ ${TOTAL_MEM_GB}GB: 軽量モデルをインストール"
  echo ""
  echo -e "  ${YELLOW}Gemma 4 E2B (軽量モデル)をダウンロード中...${NC}"
  ollama pull gemma4:e2b
  echo -e "${GREEN}  OK - gemma4:e2b${NC}"
fi

# --- Step 4: Launcher Script ---
echo ""
echo -e "${BOLD}[4/4] 起動スクリプトの作成...${NC}"

INSTALL_DIR="$HOME/.local-ai-dev-kit"
mkdir -p "$INSTALL_DIR"

# Main launcher
cat > "$INSTALL_DIR/start.sh" << 'LAUNCHER'
#!/bin/bash
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Local AI Dev Kit${NC} - Starting..."
echo ""

# Start ollama if not running
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
  echo "Ollamaサーバーを起動中..."
  ollama serve &>/dev/null &
  sleep 3
fi

# Detect available models
MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
GEMMA26B=$(echo "$MODELS" | grep "gemma4:26b" || true)
GEMMAE4B=$(echo "$MODELS" | grep "gemma4:e4b" || true)
GEMMAE2B=$(echo "$MODELS" | grep "gemma4:e2b" || true)

echo "利用可能なモデル:"
IDX=0
if [[ -n "$GEMMA26B" ]]; then
  IDX=$((IDX+1)); echo -e "  ${GREEN}[$IDX] gemma4:26b${NC} - 高性能（他のアプリを閉じて使用推奨）"
fi
if [[ -n "$GEMMAE4B" ]]; then
  IDX=$((IDX+1)); echo -e "  ${GREEN}[$IDX] gemma4:e4b${NC} - 中量（他のアプリと共存可能）"
fi
if [[ -n "$GEMMAE2B" ]]; then
  IDX=$((IDX+1)); echo -e "  ${GREEN}[$IDX] gemma4:e2b${NC} - 軽量（16GB Macでも快適）"
fi
echo ""

# Auto-select best available model
if [[ -n "$GEMMAE4B" ]]; then
  DEFAULT_MODEL="gemma4:e4b"
elif [[ -n "$GEMMAE2B" ]]; then
  DEFAULT_MODEL="gemma4:e2b"
elif [[ -n "$GEMMA26B" ]]; then
  DEFAULT_MODEL="gemma4:26b"
fi

# If only one model, skip selection
AVAILABLE=0
[[ -n "$GEMMA26B" ]] && AVAILABLE=$((AVAILABLE+1))
[[ -n "$GEMMAE4B" ]] && AVAILABLE=$((AVAILABLE+1))
[[ -n "$GEMMAE2B" ]] && AVAILABLE=$((AVAILABLE+1))

if [[ $AVAILABLE -le 1 ]]; then
  MODEL="$DEFAULT_MODEL"
else
  read -p "モデルを選択 (default: $DEFAULT_MODEL): " choice
  case $choice in
    *26b*) MODEL="gemma4:26b" ;;
    *e4b*) MODEL="gemma4:e4b" ;;
    *e2b*) MODEL="gemma4:e2b" ;;
    *) MODEL="$DEFAULT_MODEL" ;;
  esac
fi

echo ""
echo -e "${GREEN}$MODEL で起動します${NC}"
echo -e "${YELLOW}終了するには /bye と入力してください${NC}"
echo ""

# Run with thinking disabled for speed
ollama run "$MODEL" /set parameter think off 2>/dev/null
ollama run "$MODEL"
LAUNCHER
chmod +x "$INSTALL_DIR/start.sh"

# Claude Code launcher
cat > "$INSTALL_DIR/start-claude.sh" << 'CLAUDE_LAUNCHER'
#!/bin/bash
BOLD='\033[1m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Local AI Dev Kit${NC} - Claude Code Mode"
echo -e "Claude Codeのインターフェースでローカルモデルを使用します"
echo ""

# Start ollama if not running
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
  echo "Ollamaサーバーを起動中..."
  ollama serve &>/dev/null &
  sleep 3
fi

if ! command -v claude &> /dev/null; then
  echo "Error: Claude Codeがインストールされていません"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi

echo -e "${GREEN}Claude Codeをローカルモデルで起動します...${NC}"
echo ""

ANTHROPIC_BASE_URL=http://localhost:11434 \
ANTHROPIC_API_KEY="local" \
claude
CLAUDE_LAUNCHER
chmod +x "$INSTALL_DIR/start-claude.sh"

# Add to PATH via symlink
mkdir -p "$HOME/.local/bin"
ln -sf "$INSTALL_DIR/start.sh" "$HOME/.local/bin/local-ai"
ln -sf "$INSTALL_DIR/start-claude.sh" "$HOME/.local/bin/local-claude"

echo -e "${GREEN}  OK - 起動スクリプト作成完了${NC}"

# --- Done ---
echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}  セットアップ完了！${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo "  使い方:"
echo ""
echo "    ${BOLD}local-ai${NC}        チャットモードで起動"
echo "    ${BOLD}local-claude${NC}    Claude Codeモードで起動"
echo ""
echo "  ※ 初回はターミナルを再起動してください"
echo ""
echo -e "${BOLD}  セキュリティについて${NC}"
echo "  - 全ての処理はこのMac上で完結します"
echo "  - AIモデルはローカルに保存されています"
echo "  - インターネット接続は不要です"
echo "  - 入力データが外部に送信されることはありません"
echo ""
