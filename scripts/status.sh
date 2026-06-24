#!/bin/bash
# ============================================
# 查看服务状态 (Check Service Status)
# 用法: ./scripts/status.sh
# ============================================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PORT="${PORT:-8000}"
WEBUI_PORT="${WEBUI_PORT:-7860}"

echo "============================================"
echo "  仪玄角色助手 - 服务状态"
echo "============================================"
echo ""

# vLLM 状态
echo -n "1. vLLM 推理服务 (port $PORT): "
if curl -s http://localhost:$PORT/v1/models 2>/dev/null | grep -q "yixuan"; then
    echo -e "${GREEN}✅ 运行中${NC}"
    echo "   模型列表:"
    curl -s http://localhost:$PORT/v1/models | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data['data']:
    print(f'   - {m[\"id\"]}')
" 2>/dev/null
else
    echo -e "${RED}❌ 未运行${NC}"
    echo "   启动: ./scripts/start-vllm.sh"
fi
echo ""

# Gradio 状态
echo -n "2. Gradio 网页界面 (port $WEBUI_PORT): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:$WEBUI_PORT 2>/dev/null | grep -q "200\|302"; then
    echo -e "${GREEN}✅ 运行中${NC}"
    echo "   访问: http://localhost:$WEBUI_PORT"
else
    echo -e "${RED}❌ 未运行${NC}"
    echo "   启动: ./scripts/start-webui.sh"
fi
echo ""

# OpenCode 状态
echo -n "3. OpenCode: "
if command -v opencode &> /dev/null; then
    echo -e "${GREEN}✅ 已安装${NC} ($(opencode --version 2>/dev/null || echo 'unknown'))"
    if [ -f ~/.config/opencode/config.json ]; then
        echo "   配置: ~/.config/opencode/config.json"
    fi
else
    echo -e "${RED}❌ 未安装${NC}"
    echo "   安装: ./scripts/setup-opencode.sh"
fi
echo ""

# GPU 状态
echo "4. GPU 显存状态:"
if command -v rocm-smi &> /dev/null; then
    rocm-smi --showmeminfo vram 2>/dev/null | grep "VRAM" | head -2
elif command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
else
    echo "   未找到 GPU 监控工具"
fi
echo ""

echo "============================================"
