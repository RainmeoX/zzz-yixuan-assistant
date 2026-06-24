#!/bin/bash
# ============================================
# 停止所有服务 (Stop All Services)
# 用法: ./scripts/stop-all.sh
# ============================================

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}停止所有服务...${NC}"

# 停止 vLLM
pkill -f "vllm serve" 2>/dev/null && echo -e "${GREEN}✅ vLLM 已停止${NC}" || echo "vLLM 未运行"

# 停止 Gradio
pkill -f "python.*app.py" 2>/dev/null && echo -e "${GREEN}✅ Gradio 已停止${NC}" || echo "Gradio 未运行"

# 停止 OpenCode
pkill -f "opencode" 2>/dev/null && echo -e "${GREEN}✅ OpenCode 已停止${NC}" || echo "OpenCode 未运行"

echo ""
echo -e "${GREEN}所有服务已停止${NC}"
