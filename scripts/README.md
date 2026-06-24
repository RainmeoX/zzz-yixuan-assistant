# 脚本说明 (Scripts)

## 📁 脚本列表

| 脚本 | 中文名称 | 功能 |
|---|---|---|
| `deploy-all.sh` | 一键部署 | 启动 vLLM + 配置 OpenCode |
| `start-vllm.sh` | 启动推理服务 | 启动 vLLM 推理服务 (端口 8000) |
| `start-webui.sh` | 启动网页界面 | 启动 Gradio 网页界面 (端口 7860) |
| `setup-opencode.sh` | 配置 OpenCode | 安装并配置 OpenCode |
| `chat.sh` | 命令行对话 | 单条命令行对话 |
| `status.sh` | 查看状态 | 查看所有服务运行状态 |
| `stop-all.sh` | 停止所有服务 | 停止 vLLM + Gradio + OpenCode |

## 🚀 使用方法

### 首次使用 (First Time)

```bash
# 一键部署（启动 vLLM + 配置 OpenCode）
./scripts/deploy-all.sh
```

### 日常使用 (Daily Use)

```bash
# 1. 启动推理服务
./scripts/start-vllm.sh

# 2. 对话（三选一）
./scripts/chat.sh "你是谁？"           # 命令行
opencode run "你是谁？"                # OpenCode
./scripts/start-webui.sh               # 网页界面

# 3. 查看状态
./scripts/status.sh

# 4. 停止所有服务
./scripts/stop-all.sh
```

## ⚙️ 配置 (Configuration)

所有脚本支持环境变量配置：

```bash
# 自定义模型路径
export MODEL_PATH=./models/Qwen/Qwen3-4B
export LORA_PATH=./output/Qwen3_Yixuan_LoRA_final

# 自定义端口
export PORT=8000          # vLLM 端口
export WEBUI_PORT=7860    # Gradio 端口

# 然后运行脚本
./scripts/deploy-all.sh
```

## 📋 脚本执行顺序

```
deploy-all.sh
├── start-vllm.sh        (启动 vLLM)
└── setup-opencode.sh    (配置 OpenCode)

# 独立使用
start-webui.sh           (需要先运行 start-vllm.sh)
chat.sh                  (需要先运行 start-vllm.sh)
status.sh                (随时可运行)
stop-all.sh              (随时可运行)
```
