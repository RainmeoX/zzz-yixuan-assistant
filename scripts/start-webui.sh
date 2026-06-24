#!/bin/bash
# ============================================
# 启动网页界面 (Start Web UI - Gradio)
# 用法: ./scripts/start-webui.sh
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

# ============================================
# 配置 (Configuration)
# ============================================
MODEL_PATH="${MODEL_PATH:-./models/Qwen/Qwen3-4B}"
LORA_PATH="${LORA_PATH:-./output/Qwen3_Yixuan_LoRA_final}"
WEBUI_PORT="${WEBUI_PORT:-7860}"

# ⚠️ AMD RX 7900 XTX (gfx1100) 必须设置
export HSA_OVERRIDE_GFX_VERSION=11.0.0

# ============================================
# 环境检查 (Environment Check)
# ============================================
print_info "检查环境..."

if [ ! -d "$MODEL_PATH" ]; then
    print_error "模型路径不存在: $MODEL_PATH"
    exit 1
fi

if [ ! -d "$LORA_PATH" ]; then
    print_error "LoRA 权重不存在: $LORA_PATH"
    exit 1
fi

if ! python3 -c "import gradio" 2>/dev/null; then
    print_info "安装 gradio..."
    pip install -q gradio -i https://mirrors.cloud.tencent.com/pypi/simple/
fi

# ============================================
# 启动 Gradio (Start Gradio)
# ============================================
print_info "启动 Gradio 网页界面..."
print_info "  模型路径 (Model): $MODEL_PATH"
print_info "  LoRA 路径 (LoRA): $LORA_PATH"
print_info "  网页端口 (Port): $WEBUI_PORT"

python3 app.py \
    --base_model_path "$MODEL_PATH" \
    --lora_path "$LORA_PATH" \
    --port $WEBUI_PORT
