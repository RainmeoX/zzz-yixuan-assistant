# Style Chat Assistant

> 风格约束对话助手：LoRA 微调 + RAG 检索增强 + vLLM 推理部署的完整工程链路 ｜ AMD ROCm 单卡实战

本仓库是**可复用的通用方案**：换掉语料与设定文件，即可迁移到任意领域。「绝区零仪玄」只是当前的演示实例。

基于 Qwen3-4B 构建的领域风格对话系统，验证「微调学风格 + 检索保知识 + 校验器控一致性」三层方案在消费级单卡上的可行性。

## 架构（前后端分离）

```
前端 (stream-chat-webui)          后端（本仓库）
┌─────────────────┐              ┌─────────────────────┐
│  纯 HTML/CSS/JS  │ ──API请求──→ │  vLLM 推理服务       │
│  主题化 UI       │ ←─响应────  │  (端口 8000)         │
│  静态文件        │              │  Qwen3-4B + LoRA     │
└─────────────────┘              └─────────────────────┘
```

| 仓库 | 职责 | 地址 |
|---|---|---|
| **后端（本仓库）** | 模型训练 + vLLM 推理服务 | [style-chat-assistant](https://github.com/RainmeoX/style-chat-assistant) |
| **前端** | 流式对话 WebUI | [stream-chat-webui](https://github.com/RainmeoX/stream-chat-webui) |
| **语料管线** | 领域语料爬取与结构化 | [domain-corpus-pipeline](https://github.com/RainmeoX/domain-corpus-pipeline) |

## 核心设计：三层一致性方案

```
微调模型（学表达风格） + 领域知识库（保事实准确） + 输出校验器（控风格漂移）
```

| 能力 | 实现方式 |
|:---|:---|
| 风格一致性 | LoRA 微调注入特定表达风格，校验器拦截风格漂移与 AI 自白 |
| 知识准确性 | ChromaDB 外挂检索（实体设定 + 领域语料），答案可溯源 |
| 多轮对话 | 上下文管理 + 思考过程（thinking）可控输出 |
| 流式交互 | vLLM streaming + 前端逐 token 渲染 |

## 模型信息

| 项目 | 内容 |
|:---|:---|
| 基础模型 | Qwen3-4B |
| 微调方法 | LoRA（r=16, alpha=32） |
| 训练数据 | 领域风格语料 468 条 Q&A |
| 外挂数据库 | ChromaDB（实体设定 + 领域语料） |
| 训练环境 | AMD Radeon RX 7900 XTX（gfx1100） |
| 训练时长 | 约 15–30 分钟 |
| 显存占用 | ~15–18 GB |
| LoRA adapter | ~40MB |

## 快速开始

### 一键部署（已完成训练）

```bash
./scripts/deploy-all.sh   # 启动 vLLM + 配置 OpenCode 客户端
opencode run "你是谁？"
```

### 完整流程（首次使用）

```bash
git clone https://github.com/RainmeoX/style-chat-assistant.git
cd style-chat-assistant
git clone https://github.com/RainmeoX/domain-corpus-pipeline.git

pip install -r requirements.txt
python -c "from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-4B', cache_dir='./models')"

jupyter notebook 01-Qwen3-Yixuan-LoRA.ipynb   # 按序运行训练 cells
./scripts/deploy-all.sh
```

### vLLM 启动（AMD ROCm 专用参数）

```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export VLLM_USE_TRITON_FLASH_ATTN=0
export VLLM_USE_ROCM_FLASH_ATTN=1

vllm serve ./models/Qwen/Qwen3-4B \
    --port 8000 \
    --enable-lora \
    --lora-modules style-lora=./output/Qwen3_Yixuan_LoRA_final \
    --max-model-len 32768 \
    --gpu-memory-utilization 0.85 \
    --dtype bfloat16 \
    --trust-remote-code \
    --enforce-eager \
    --enable-auto-tool-choice \
    --tool-call-parser hermes \
    --reasoning-parser deepseek_r1
```

## AMD RDNA3 (gfx1100) 适配要点

消费级 RDNA3 显卡跑 vLLM 的三个关键点（踩坑实录）：

1. `HSA_OVERRIDE_GFX_VERSION=11.0.0` 必须设置，否则 PyTorch 找不到 GPU
2. RDNA3 不支持 Triton FlashAttention，需切换 `VLLM_USE_ROCM_FLASH_ATTN=1` 并 `--enforce-eager` 规避图捕获问题
3. PyTorch 需安装 ROCm 版：`pip install torch --index-url https://download.pytorch.org/whl/rocm6.2`

## 项目结构

```
style-chat-assistant/
├── 01-Qwen3-Yixuan-LoRA.ipynb   # 训练 notebook
├── app.py                        # Gradio 界面（备用）
├── yixuan_enhanced.json          # 468 条训练语料
├── generate_predictions.py       # 评估脚本
├── opencode_config.json          # OpenCode 配置模板
└── scripts/                      # 部署/启停/对话脚本集
    ├── deploy-all.sh             # 一键部署
    ├── start-vllm.sh             # 启动推理服务
    └── ...
```

## 项目不足

- 输出校验器规则依赖人工维护，尚未做成可配置的规则引擎
- 未做系统化评测集，风格一致性靠人工抽检
- 仅在 RDNA3 单卡验证，未覆盖其他 GPU 架构

## 后续计划

- 输出一致性校验器规则化、配置化
- 增加自动化评测（风格相似度 + 知识准确率双指标）
- 抽象为通用「领域风格对话」模板

## License

MIT
