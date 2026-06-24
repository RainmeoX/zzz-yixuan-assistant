#!/bin/bash
# ============================================
# 一键部署 (One-Click Deploy)
# 用法: ./scripts/deploy-all.sh
# 功能: 启动 vLLM + 配置 OpenCode
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  仪玄角色助手 - 一键部署"
echo "============================================"
echo ""

# 步骤 1: 启动 vLLM
echo -e "${BLUE}[1/2] 启动 vLLM 推理服务...${NC}"
bash "$SCRIPT_DIR/start-vllm.sh"
echo ""

# 步骤 2: 配置 OpenCode
echo -e "${BLUE}[2/2] 配置 OpenCode...${NC}"
bash "$SCRIPT_DIR/setup-opencode.sh"
echo ""

echo "============================================"
echo -e "${GREEN}✅ 部署完成！(Deploy Complete!)${NC}"
echo "============================================"
echo ""
echo "使用方法 (Usage):"
echo ""
echo "  1. OpenCode 对话 (推荐):"
echo "     opencode"
echo "     opencode run \"你是谁？\""
echo ""
echo "  2. 命令行对话:"
echo "     ./scripts/chat.sh \"你是谁？\""
echo ""
echo "  3. 网页界面:"
echo "     ./scripts/start-webui.sh"
echo ""
echo "  4. 查看状态:"
echo "     ./scripts/status.sh"
echo ""
echo "  5. 停止所有服务:"
echo "     ./scripts/stop-all.sh"
echo ""
