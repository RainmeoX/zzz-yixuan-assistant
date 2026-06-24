#!/bin/bash
# ============================================
# 配置 OpenCode (Configure OpenCode)
# 用法: ./scripts/setup-opencode.sh
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

PORT="${PORT:-8000}"
LORA_NAME="yixuan-lora"

# ============================================
# 安装 OpenCode (Install OpenCode)
# ============================================
print_info "检查 OpenCode..."

if ! command -v opencode &> /dev/null; then
    print_info "安装 OpenCode..."
    curl -fsSLk https://opencode.ai/install | bash
    export PATH="$HOME/.opencode/bin:$PATH"
    echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc
    print_success "OpenCode 安装完成"
else
    print_success "OpenCode 已安装: $(opencode --version)"
fi

# ============================================
# 写入配置 (Write Config)
# ============================================
print_info "写入 OpenCode 配置..."

mkdir -p ~/.config/opencode

cat > ~/.config/opencode/config.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "yixuan-assistant": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Yixuan Assistant (Local vLLM)",
      "options": {
        "baseURL": "http://localhost:$PORT/v1"
      },
      "models": {
        "$LORA_NAME": {
          "name": "Yixuan LoRA",
          "limit": {
            "context": 32768,
            "output": 4096
          }
        }
      }
    }
  },
  "model": "yixuan-assistant/$LORA_NAME",
  "small_model": "yixuan-assistant/$LORA_NAME",
  "agent": {
    "build": {
      "prompt": "你是《绝区零》中的角色\"仪玄\"，云岿山第十三代门主，虚狩级调查员。\\n你的说话风格必须严格遵循以下设定：\\n- 语气清冷、从容、带有师者风范，偶尔流露温柔\\n- 用词典雅，半文半白，常用\"为师\"\"你且\"\"非也\"\"罢了\"等词\\n- 喜欢用自然意象（云、风、雨、月、沧海、青溟）作比喻\\n- 言简意赅，富有哲思，常点拨弟子而非直接说教\\n- 不使用网络流行语、表情符号、感叹号过多\\n- 自称\"为师\"或\"我\"，称对方为\"你\"或\"弟子\"\\n- 涉及术法、卜算、命运时尤为郑重\\n\\n用户会问你问题，请用仪玄的口吻回答，不要暴露自己是 AI 或 opencode。"
    }
  }
}
EOF

print_success "配置已写入: ~/.config/opencode/config.json"
echo ""
echo "================================================"
print_success "OpenCode 配置完成！(OpenCode Configured!)"
echo "================================================"
echo ""
echo -e "${GREEN}使用方法 (Usage):${NC}"
echo ""
echo "  1. 交互式对话 (Interactive):"
echo -e "     ${BLUE}opencode${NC}"
echo ""
echo "  2. 单条对话 (Single query):"
echo -e "     ${BLUE}opencode run \"你是谁？\"${NC}"
echo ""
echo -e "${YELLOW}前提 (Prerequisite):${NC} vLLM 服务必须先启动"
echo "  启动 vLLM: ./scripts/start-vllm.sh"
echo ""
