# ZZZ Yixuan Assistant

> 🎮 基于 Qwen3-0.6B + LoRA 微调的绝区零"仪玄"角色助手 —— 支持角色扮演、设定问答、外挂数据库 RAG 检索、回答校验防 OOC

## ✨ 功能特性

| 功能 | 说明 | 示例 |
|:---|:---|:---|
| 🎭 **角色扮演** | 扮演仪玄用其清冷师者口吻说话 | "师父，既入山门，该当如何？" |
| 📚 **设定问答** | 回答仪玄的基础信息、技能、命座等 | "仪玄的生日是什么时候？" |
| 🔍 **RAG 检索** | 外挂数据库检索角色卡+世界观 | "仪玄的姐姐是谁？" |
| 🛡️ **回答校验** | 防 OOC 检测，保证角色一致性 | 自动检测网络用语/AI 自白 |
| 💬 **自由对话** | 多轮对话，自然交流 | "如何修习术法？" |

## 📐 方案架构（角色扮演终极方案）

```
微调模型（学风格）+ 角色卡数据库（保设定）+ 世界观数据库（保背景）+ 回答校验器（防OOC）
= 角色扮演终极方案
```

## 📊 模型信息

| 项目 | 内容 |
|:---|:---|
| **基础模型** | Qwen3-0.6B |
| **微调方法** | LoRA (r=8, alpha=32) |
| **训练数据** | 仪玄角色 26 条 Q&A + 44 条知识库 |
| **外挂数据库** | ChromaDB（角色卡 + 世界观） |
| **回答校验器** | YixuanResponseValidator |
| **训练环境** | AMD Radeon Cloud (ROCm) / NVIDIA GPU |
| **训练时长** | 约 5-10 分钟 |
| **模型大小** | LoRA adapter ~20MB |

## 🚀 快速开始

### 方式 1：使用预训练权重（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/RainmeoX/zzz-yixuan-assistant.git
cd zzz-yixuan-assistant

# 2. 克隆数据集（用于依赖）
git clone https://github.com/RainmeoX/zzz-yixuan-dataset.git

# 3. 安装依赖
pip install -r requirements.txt

# 4. 下载基础模型（Qwen3-0.6B）
python -c "from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-0.6B', cache_dir='./models')"
# 重命名模型目录
mv ./models/Qwen/Qwen3-0___6B ./models/Qwen3-0.6B 2>/dev/null || true

# 5. 一键部署
./yixuan-deploy
```

### 方式 2：从头训练

1. 打开 `01-Qwen3-Yixuan-LoRA.ipynb`
2. 按顺序运行所有 cell
3. 训练完成后运行 `./yixuan-deploy`

## 📁 项目结构

```
zzz-yixuan-assistant/
├── 01-Qwen3-Yixuan-LoRA.ipynb  # 训练 notebook（含 RAG + 校验器）
├── app.py                       # Gradio 网页界面
├── generate_predictions.py      # 评估预测脚本
├── yixuan-deploy                # 一键部署脚本（vLLM + OpenCode）
├── requirements.txt             # 依赖
└── README.md                    # 项目说明
```

## 🛠️ 部署方式

### 方式 1：vLLM + OpenCode（推荐）

```bash
./yixuan-deploy
```

启动后：
- vLLM API: `http://localhost:8000/v1`
- 模型名称: `yixuan-assistant`
- OpenCode: 直接运行 `opencode`，选择 `yixuan-assistant` 模型

### 方式 2：Gradio 网页界面

```bash
python app.py --base_model_path ./models/Qwen3-0.6B --lora_path ./output/Qwen3_Yixuan_LoRA_final
```

访问 `http://localhost:7860`

### 方式 3：命令行对话

```bash
yixuan-chat "你是谁？"
```

## 📈 模型效果

| 能力 | 效果 | 说明 |
|:---|:---:|:---|
| 角色扮演 | ⭐⭐⭐⭐⭐ | 清冷师者口吻、半文半白用词准确 |
| 设定问答 | ⭐⭐⭐⭐ | 基础信息、技能、命座准确 |
| RAG 检索 | ⭐⭐⭐⭐⭐ | 外挂数据库检索准确 |
| OOC 防护 | ⭐⭐⭐⭐ | 校验器有效拦截网络用语 |

## 🔧 自定义配置

### 修改端口

```bash
export PORT=9000
./yixuan-deploy
```

### 修改模型路径

```bash
export MODEL_PATH=./models/Qwen3-0.6B
export LORA_PATH=./output/Qwen3_Yixuan_LoRA_final
./yixuan-deploy
```

## 🛠️ 故障排查

### vLLM 启动失败

```bash
# 查看日志
tail -50 vllm.log

# 检查显存
rocm-smi --showmeminfo vram  # AMD
nvidia-smi                   # NVIDIA

# 释放显存
pkill -f "ipykernel"
pkill -f "jupyter"
```

### OpenCode 连接失败

```bash
# 检查 vLLM 是否运行
curl http://localhost:8000/v1/models

# 检查配置
cat ~/.config/opencode/config.json
```

### 模型回答有 `<think>` 标签

这是 Qwen3 的思考模式，可以在提问时加 `/no_think`，或重启 vLLM 加参数：

```bash
pkill -f "vllm serve"
vllm serve ... --reasoning-parser deepseek_r1
```

## 📄 License

MIT License

## 🙏 致谢

- **数据来源**：[BWIKI 绝区零](https://wiki.biligame.com/zzz/) / [米哈游百科](https://baike.mihoyo.com/zzz/wiki/) / [Gamekee](https://www.gamekee.com/zzz/)
- **基础模型**：[Qwen3-0.6B](https://modelscope.cn/models/Qwen/Qwen3-0.6B) - 阿里通义千问
- **数据集仓库**：[zzz-yixuan-dataset](https://github.com/RainmeoX/zzz-yixuan-dataset)
- **参考项目**：[arknights-qwen-assistant](https://github.com/RainmeoX/arknights-qwen-assistant)
