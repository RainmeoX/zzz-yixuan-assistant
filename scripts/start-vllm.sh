#!/bin/bash
# ============================================
# 启动 vLLM 推理服务 (Start vLLM Inference Server)
# 用法: ./scripts/start-vllm.sh
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
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# 配置 (Configuration)
# ============================================
MODEL_PATH="${MODEL_PATH:-./models/Qwen/Qwen3-4B}"
LORA_PATH="${LORA_PATH:-./output/Qwen3_Yixuan_LoRA_final}"
PORT="${PORT:-8000}"
MODEL_NAME="yixuan-assistant"
LORA_NAME="yixuan-lora"
VLLM_LOG="vllm.log"

# ⚠️ AMD RX 7900 XTX (gfx1100) 必须设置
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export VLLM_USE_TRITON_FLASH_ATTN=0
export VLLM_USE_ROCM_FLASH_ATTN=1

# ============================================
# 环境检查 (Environment Check)
# ============================================
print_info "检查环境..."

if [ ! -d "$MODEL_PATH" ]; then
    print_error "模型路径不存在: $MODEL_PATH"
    print_info "请先下载模型: python -c \"from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-4B', cache_dir='./models')\""
    exit 1
fi

if [ ! -d "$LORA_PATH" ]; then
    print_error "LoRA 权重不存在: $LORA_PATH"
    print_info "请先运行 notebook 训练模型"
    exit 1
fi

# 释放显存 (Release VRAM)
print_info "释放显存..."
pkill -f "ipykernel" 2>/dev/null || true
pkill -f "jupyter" 2>/dev/null || true
pkill -f "python app.py" 2>/dev/null || true
pkill -f "vllm serve" 2>/dev/null || true
sleep 2

# ============================================
# 启动 vLLM (Start vLLM)
# ============================================
print_info "启动 vLLM 服务..."
print_info "  模型路径 (Model): $MODEL_PATH"
print_info "  LoRA 路径 (LoRA): $LORA_PATH"
print_info "  端口 (Port): $PORT"

nohup vllm serve "$MODEL_PATH" \
    --port $PORT \
    --served-model-name $MODEL_NAME \
    --enable-lora \
    --lora-modules $LORA_NAME=$LORA_PATH \
    --max-model-len 32768 \
    --gpu-memory-utilization 0.85 \
    --dtype bfloat16 \
    --trust-remote-code \
    --enforce-eager \
    --enable-auto-tool-choice \
    --tool-call-parser hermes \
    --reasoning-parser deepseek_r1 \
    > $VLLM_LOG 2>&1 &

VLLM_PID=$!
print_info "vLLM PID: $VLLM_PID"
print_info "日志文件: $VLLM_LOG"

# ============================================
# 等待启动 (Wait for Startup)
# ============================================
print_info "等待 vLLM 启动（最多 120 秒）..."

for i in $(seq 1 60); do
    if curl -s http://localhost:$PORT/v1/models 2>/dev/null | grep -q "$MODEL_NAME"; then
        print_success "vLLM 已启动！"
        break
    fi
    if [ $i -eq 60 ]; then
        print_error "vLLM 启动超时"
        print_info "查看日志: tail -50 $VLLM_LOG"
        exit 1
    fi
    sleep 2
    printf "."
done

echo ""
echo "================================================"
print_success "vLLM 服务已就绪！(vLLM Server Ready)"
echo "================================================"
echo ""
echo -e "${GREEN}API 地址 (API URL):${NC}  http://localhost:$PORT/v1"
echo -e "${GREEN}基础模型 (Base):${NC}     $MODEL_NAME"
echo -e "${GREEN}LoRA 模型 (LoRA):${NC}    $LORA_NAME (用这个对话)"
echo ""
echo -e "${YELLOW}下一步 (Next):${NC}"
echo "  1. 启动 OpenCode:  ./scripts/start-opencode.sh"
echo "  2. 启动网页界面:   ./scripts/start-webui.sh"
echo "  3. 命令行对话:     ./scripts/chat.sh \"你是谁？\""
echo ""
