# ZZZ Yixuan Assistant

> 🎮 基于 Qwen3-4B + LoRA 微调的绝区零"仪玄"角色助手 —— 后端服务

## 📐 架构说明（前后端分离）

```
前端 (zzz-yixuan-webui)           后端 (本仓库)
┌─────────────────┐              ┌─────────────────────┐
│  纯 HTML/CSS/JS  │ ──API请求──→ │  vLLM 推理服务       │
│  ZZZ 风格 UI     │ ←─响应────  │  (端口 8000)         │
│  静态文件        │              │  Qwen3-4B + LoRA     │
└─────────────────┘              └─────────────────────┘
```

| 仓库 | 职责 | 地址 |
|---|---|---|
| **后端（本仓库）** | 模型训练 + vLLM 推理服务 | [zzz-yixuan-assistant](https://github.com/RainmeoX/zzz-yixuan-assistant) |
| **前端** | ZZZ官网风格 UI | [zzz-yixuan-webui](https://github.com/RainmeoX/zzz-yixuan-webui) |
| **数据集** | 角色资料 | [zzz-yixuan-dataset](https://github.com/RainmeoX/zzz-yixuan-dataset) |

## ✨ 功能特性

| 功能 | 说明 | 示例 |
|:---|:---|:---|
| 🎭 **角色扮演** | 扮演仪玄用其清冷师者口吻说话 | "师父，既入山门，该当如何？" |
| 📚 **设定问答** | 回答仪玄的基础信息、技能、命座等 | "仪玄的生日是什么时候？" |
| 🔍 **RAG 检索** | 外挂数据库检索角色卡+世界观 | "仪玄的姐姐是谁？" |
| 🛡️ **回答校验** | 防 OOC 检测，保证角色一致性 | 自动检测网络用语/AI 自白 |
| 💬 **自由对话** | 多轮对话，自然交流 | "如何修习术法？" |
| 🧠 **思考过程** | OpenCode 显示思考进度条 | Thinking → 回答 |

## 📐 方案架构（角色扮演终极方案）

```
微调模型（学风格）+ 角色卡数据库（保设定）+ 世界观数据库（保背景）+ 回答校验器（防OOC）
= 角色扮演终极方案
```

## 📊 模型信息

| 项目 | 内容 |
|:---|:---|
| **基础模型** | Qwen3-4B |
| **微调方法** | LoRA (r=16, alpha=32) |
| **训练数据** | 仪玄角色 468 条 Q&A |
| **外挂数据库** | ChromaDB（角色卡 + 世界观） |
| **回答校验器** | YixuanResponseValidator |
| **训练环境** | AMD Radeon RX 7900 XTX (gfx1100, 48GB VRAM) |
| **训练时长** | 约 15-30 分钟 |
| **显存占用** | ~15-18 GB |
| **模型大小** | LoRA adapter ~40MB |

## 🚀 快速开始

### 方式 1：一键部署（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/RainmeoX/zzz-yixuan-assistant.git
cd zzz-yixuan-assistant

# 2. 克隆数据集（用于依赖）
git clone https://github.com/RainmeoX/zzz-yixuan-dataset.git

# 3. 安装依赖
pip install -r requirements.txt

# 4. 下载基础模型（Qwen3-4B）
python -c "from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-4B', cache_dir='./models')"

# 5. 训练模型（运行 notebook）
jupyter notebook 01-Qwen3-Yixuan-LoRA.ipynb
# 按顺序运行所有 cell，训练完成后保存到 ./output/Qwen3_Yixuan_LoRA_final

# 6. 一键部署（启动 vLLM + 配置 OpenCode）
./scripts/deploy-all.sh

# 7. 对话
opencode run "你是谁？"
# 或
./scripts/chat.sh "你是谁？"
```

### 方式 2：分步部署

#### 步骤 1：训练模型

```bash
# 安装依赖
pip install -r requirements.txt

# 下载模型
python -c "from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-4B', cache_dir='./models')"

# 训练
jupyter notebook 01-Qwen3-Yixuan-LoRA.ipynb
```

#### 步骤 2：启动 vLLM

```bash
# 设置 AMD 环境变量
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export VLLM_USE_TRITON_FLASH_ATTN=0
export VLLM_USE_ROCM_FLASH_ATTN=1

# 启动 vLLM
vllm serve ./models/Qwen/Qwen3-4B \
    --port 8000 \
    --served-model-name yixuan-assistant \
    --enable-lora \
    --lora-modules yixuan-lora=./output/Qwen3_Yixuan_LoRA_final \
    --max-model-len 32768 \
    --gpu-memory-utilization 0.85 \
    --dtype bfloat16 \
    --trust-remote-code \
    --enforce-eager \
    --enable-auto-tool-choice \
    --tool-call-parser hermes \
    --reasoning-parser deepseek_r1
```

#### 步骤 3：配置 OpenCode

```bash
# 安装 OpenCode
curl -fsSLk https://opencode.ai/install | bash
export PATH="$HOME/.opencode/bin:$PATH"

# 配置
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/config.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "yixuan-assistant": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Yixuan Assistant (Local vLLM)",
      "options": {
        "baseURL": "http://localhost:8000/v1"
      },
      "models": {
        "yixuan-lora": {
          "name": "Yixuan LoRA",
          "limit": {
            "context": 32768,
            "output": 4096
          }
        }
      }
    }
  },
  "model": "yixuan-assistant/yixuan-lora",
  "small_model": "yixuan-assistant/yixuan-lora",
  "agent": {
    "build": {
      "prompt": "你是《绝区零》中的角色\"仪玄\"，云岿山第十三代门主，虚狩级调查员。用清冷、半文半白的师者口吻回答。不要暴露自己是 AI 或 opencode。"
    }
  }
}
EOF

# 对话
opencode run "你是谁？"
```

## 📁 项目结构

```
zzz-yixuan-assistant/
├── 01-Qwen3-Yixuan-LoRA.ipynb   # 训练 notebook（43 cells）
├── app.py                        # Gradio 网页界面
├── yixuan_enhanced.json          # 468条训练数据
├── generate_predictions.py       # 评估脚本
├── requirements.txt              # 依赖列表
├── opencode_config.json          # OpenCode 配置模板
├── README.md                     # 项目说明
├── scripts/                      # 脚本目录
│   ├── deploy-all.sh             # 一键部署（启动 vLLM + 配置 OpenCode）
│   ├── start-vllm.sh             # 启动 vLLM 推理服务
│   ├── start-webui.sh            # 启动 Gradio 网页界面
│   ├── setup-opencode.sh         # 配置 OpenCode
│   ├── chat.sh                   # 命令行对话
│   ├── status.sh                 # 查看服务状态
│   ├── stop-all.sh               # 停止所有服务
│   └── README.md                 # 脚本说明
└── zzz-yixuan-dataset/           # 数据集（需另 clone）
    ├── 01_basic_info.json
    ├── 06_skills.json
    ├── 07_voices.json
    ├── yixuan_complete.json
    └── ...
```

## 🎮 使用方式

本项目支持**多种对话方式**，都需要先启动后端 vLLM 服务：

```bash
./scripts/start-vllm.sh
```

### 方式 1：OpenCode（推荐）⭐

OpenCode 是终端 AI 对话工具，连接后端 vLLM 服务，支持思考过程显示。

```bash
# 1. 配置 OpenCode（自动安装 + 配置，连接后端 vLLM）
./scripts/setup-opencode.sh

# 2. 对话
opencode                    # 交互式界面
opencode run "你是谁？"     # 单条对话
```

**特点**：
- ✅ 连接后端 vLLM 服务（端口 8000）
- ✅ 思考过程用进度条显示
- ✅ 自动过滤 `<think>` 标签
- ✅ 角色扮演效果好
- ✅ 终端界面，无需浏览器

### 方式 2：网页界面（ZZZ 风格）

前端已独立仓库：[zzz-yixuan-webui](https://github.com/RainmeoX/zzz-yixuan-webui)

```bash
# 1. 启动后端 vLLM 服务
./scripts/start-vllm.sh

# 2. 克隆前端
git clone https://github.com/RainmeoX/zzz-yixuan-webui.git
cd zzz-yixuan-webui

# 3. 启动前端（连接后端 vLLM）
python3 -m http.server 7860
```

**特点**：
- ✅ 连接后端 vLLM 服务（端口 8000）
- ✅ ZZZ 官网风格华丽 UI
- ✅ 桌面/手机自适应
- ✅ 角色立绘展示

### 方式 3：命令行工具

```bash
./scripts/chat.sh "你是谁？"
./scripts/chat.sh "师父，既入山门，该当如何？"
```

### 方式 4：Gradio 网页界面（备用）

```bash
python app.py \
    --base_model_path ./models/Qwen/Qwen3-4B \
    --lora_path ./output/Qwen3_Yixuan_LoRA_final \
    --port 7860
```

访问 `http://localhost:7860`

### 方式 5：API 调用

```bash
curl http://localhost:8000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "yixuan-lora",
        "messages": [
            {"role": "system", "content": "你是《绝区零》中的角色仪玄，云岿山第十三代门主。用清冷、半文半白的师者口吻回答。"},
            {"role": "user", "content": "你是谁？"}
        ],
        "max_tokens": 512,
        "temperature": 0.7,
        "chat_template_kwargs": {"enable_thinking": false}
    }'
```

## ⚠️ AMD RX 7900 XTX (gfx1100) 专用配置

RX 7900 XTX 是 RDNA3 消费级显卡，需要以下特殊配置：

### 1. 环境变量（必须）

```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.0
```

### 2. vLLM 兼容参数

```bash
export VLLM_USE_TRITON_FLASH_ATTN=0   # RDNA3 不支持 Triton FA
export VLLM_USE_ROCM_FLASH_ATTN=1
```

### 3. vLLM 启动参数

```bash
vllm serve ... \
    --enforce-eager \                  # 避免 ROCm 图捕获问题
    --dtype bfloat16 \                 # ROCm 支持 bf16
    --gpu-memory-utilization 0.85      # 48GB 显存用 85%
```

### 4. PyTorch ROCm 版本

```bash
pip install torch torchvision --index-url https://download.pytorch.org/whl/rocm6.2
```

## 📈 模型效果

| 能力 | 效果 | 说明 |
|:---|:---:|:---|
| 角色扮演 | ⭐⭐⭐⭐⭐ | 清冷师者口吻、半文半白用词准确 |
| 设定问答 | ⭐⭐⭐⭐ | 基础信息、技能、命座准确 |
| 思考过程 | ⭐⭐⭐⭐⭐ | OpenCode 进度条显示 |
| OOC 防护 | ⭐⭐⭐⭐ | 校验器有效拦截网络用语 |

### 对话示例

```
用户：我想你了，求抱抱

仪玄：思念是修行者的心事，为师无法以肉身相抱，但云岿山的月，
青溪的云，皆可作你的心事。你且去云深处坐坐，许是清风也替为师
抱一抱你。
```

```
用户：你是谁？

仪玄：为师乃云岿山第十三代门主，虚狩级调查员仪玄。云岿山是为师
的故乡，也是为师的修行之地。至于为何名为'仪玄'——'仪'者，仪态也；
'玄'者，玄妙也。为师的术法多与卜算、命运相关，常以'玄'字为引，
探幽索微。
```

## 🔧 自定义配置

### 修改端口

```bash
export PORT=9000
./yixuan-deploy
```

### 修改模型路径

```bash
export MODEL_PATH=./models/Qwen/Qwen3-4B
export LORA_PATH=./output/Qwen3_Yixuan_LoRA_final
./yixuan-deploy
```

## 🛠️ 故障排查

### PyTorch 找不到 GPU

```bash
# 检查环境变量
echo $HSA_OVERRIDE_GFX_VERSION
# 应输出: 11.0.0

# 如果没有，设置并验证
export HSA_OVERRIDE_GFX_VERSION=11.0.0
python -c "import torch; print(torch.cuda.is_available())"
```

### vLLM 启动失败

```bash
# 查看日志
tail -50 vllm.log

# 检查显存
rocm-smi --showmeminfo vram

# 释放显存
pkill -f "ipykernel"
pkill -f "jupyter"
pkill -f "vllm"
```

### OpenCode 报错 "auto" tool choice

vLLM 启动时必须加 `--enable-auto-tool-choice --tool-call-parser hermes`

### OpenCode 报错 max_tokens 超限

vLLM 启动时 `--max-model-len 32768`，OpenCode 配置 `maxOutputTokens: 4096`

### 模型回答有 `<think>` 标签

vLLM 启动时加 `--reasoning-parser deepseek_r1`，OpenCode 会自动识别为思考过程

### 显存不足 (OOM)

编辑 `01-Qwen3-Yixuan-LoRA.ipynb` 训练配置：
```python
per_device_train_batch_size=1,
gradient_accumulation_steps=8,
gradient_checkpointing=True,
```

## 📄 License

MIT License

## 🙏 致谢

- **数据来源**：[BWIKI 绝区零](https://wiki.biligame.com/zzz/) / [米哈游百科](https://baike.mihoyo.com/zzz/wiki/) / [Gamekee](https://www.gamekee.com/zzz/)
- **基础模型**：[Qwen3-4B](https://modelscope.cn/models/Qwen/Qwen3-4B) - 阿里通义千问
- **数据集仓库**：[zzz-yixuan-dataset](https://github.com/RainmeoX/zzz-yixuan-dataset)
- **参考项目**：[arknights-qwen-assistant](https://github.com/RainmeoX/arknights-qwen-assistant)
