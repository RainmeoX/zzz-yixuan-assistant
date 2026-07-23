# ZZZ Yixuan Assistant

绝区零「仪玄」角色助手后端。我用 Qwen3-4B 做 LoRA 微调，配合 vLLM 部署和 RAG 检索，做了一个能扮演这个角色、回答设定问题的本地助手。

这是一个学习项目，用来打通"数据 → 微调 → 部署 → 校验"这条链路。

## 项目背景

我想验证一件事：小参数模型（4B）通过"专属数据 + LoRA + RAG"能不能稳定扮演一个特定角色，而不只是泛泛聊天。选了绝区零的仪玄作对象。

## 系统架构

```
前端 (zzz-yixuan-webui)           后端 (本仓库)
┌─────────────────┐              ┌─────────────────────┐
│  纯 HTML/CSS/JS  │ ──API请求──→ │  vLLM 推理服务       │
│  ZZZ 风格 UI     │ ←─响应────  │  (端口 8000)         │
│  静态文件        │              │  Qwen3-4B + LoRA     │
└─────────────────┘              └─────────────────────┘
```

| 仓库 | 职责 |
|---|---|
| 后端（本仓库） | 模型训练 + vLLM 推理服务 |
| 前端 | [zzz-yixuan-webui](https://github.com/RainmeoX/zzz-yixuan-webui) |
| 数据集 | [zzz-yixuan-dataset](https://github.com/RainmeoX/zzz-yixuan-dataset) |

## 技术栈

- 基础模型：Qwen3-4B
- 微调：LoRA（r=16, alpha=32），训练数据 468 条角色 Q&A
- 外挂检索：ChromaDB（角色卡 + 世界观）
- 回答校验：YixuanResponseValidator（拦截网络用语 / AI 自白，防 OOC）
- 推理部署：vLLM
- 训练环境：AMD Radeon RX 7900 XTX（gfx1100，48GB VRAM），显存占用约 15–18 GB

## 实现功能

- 角色扮演（清冷师者口吻）
- 设定问答（基础信息、技能、命座等）
- RAG 检索外挂角色资料
- 防 OOC 校验
- 多轮对话

## 我的工作

- 设计数据采集流程，整理 468 条训练样本
- 编写 LoRA 微调 notebook
- 搭建 vLLM 推理服务并配置 ROCm 环境
- 实现防 OOC 校验器
- 编写一键部署脚本

## 开发中遇到的问题

- **AMD ROCm 兼容性**：RDNA3 不支持 Triton FA，需要 `VLLM_USE_ROCM_FLASH_ATTN=1` + `HSA_OVERRIDE_GFX_VERSION=11.0.0`，并 `--enforce-eager` 规避图捕获问题
- **角色幻觉**：靠 RAG 外挂资料 + 校验器双重约束，仍偶有越界
- **小模型能力上限**：4B 模型对复杂设定的记忆有限，长上下文靠 RAG 补

## 运行方式

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 下载基础模型
python -c "from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-4B', cache_dir='./models')"

# 3. 训练（运行 notebook）
jupyter notebook 01-Qwen3-Yixuan-LoRA.ipynb

# 4. 启动 vLLM（AMD 环境变量）
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export VLLM_USE_TRITON_FLASH_ATTN=0
export VLLM_USE_ROCM_FLASH_ATTN=1
vllm serve ./models/Qwen/Qwen3-4B --port 8000 --enable-lora \
    --lora-modules yixuan-lora=./output/Qwen3_Yixuan_LoRA_final \
    --max-model-len 32768 --dtype bfloat16 --enforce-eager
```

更完整的部署 / 前端联调 / 故障排查见仓库 `scripts/` 目录。

## 项目不足

- 训练数据规模小（468 条），角色深度有限
- 依赖 RAG 质量，资料缺失时仍会编
- 只在单张消费级显卡验证过，未做并发压测

## 后续计划

- 扩充训练数据，覆盖更多剧情向对话
- 尝试更强的基模或更大的 LoRA rank
- 加自动化评测，量化角色一致性

## Reflection

这是我第一个完整跑通"微调 + 部署 + 校验"的项目。最大的收获不是模型效果，而是理解了小模型的能力边界，以及 RAG / 校验器这类"工程补丁"在真实产品里的必要性——模型不够，工程来补。

## License

MIT
