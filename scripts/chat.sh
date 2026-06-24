#!/bin/bash
# ============================================
# 命令行对话 (CLI Chat)
# 用法: ./scripts/chat.sh "你是谁？"
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PORT="${PORT:-8000}"
LORA_NAME="yixuan-lora"

# 获取问题 (Get question)
QUESTION="${1:-你好}"

# 检查 vLLM 是否运行 (Check vLLM)
if ! curl -s http://localhost:$PORT/v1/models 2>/dev/null | grep -q "$LORA_NAME"; then
    echo -e "${RED}[ERROR]${NC} vLLM 服务未运行"
    echo -e "${YELLOW}请先启动:${NC} ./scripts/start-vllm.sh"
    exit 1
fi

# 发送请求 (Send request)
echo -e "${BLUE}问:${NC} $QUESTION"
echo -e "${GREEN}答:${NC}"

curl -s http://localhost:$PORT/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$LORA_NAME\",
        \"messages\": [
            {\"role\": \"system\", \"content\": \"你是《绝区零》中的角色仪玄，云岿山第十三代门主。用清冷、半文半白的师者口吻回答。\"},
            {\"role\": \"user\", \"content\": \"$QUESTION\"}
        ],
        \"max_tokens\": 512,
        \"temperature\": 0.7,
        \"chat_template_kwargs\": {\"enable_thinking\": false}
    }" | python3 -c "
import sys, json, re
try:
    data = json.load(sys.stdin)
    content = data['choices'][0]['message']['content']
    content = re.sub(r'<think>.*?</think>\s*', '', content, flags=re.DOTALL)
    print(content.strip())
except Exception as e:
    print(f'请求失败: {e}')
"
echo ""
