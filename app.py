"""
绝区零仪玄角色助手 - Gradio 网页界面
用法：python app.py --base_model_path ./models/Qwen3-0.6B --lora_path ./output/Qwen3_Yixuan_LoRA_final
"""
import argparse
import os
# ⚠️ AMD RX 7900 XTX (gfx1100) 必须设置此环境变量
os.environ['HSA_OVERRIDE_GFX_VERSION'] = '11.0.0'
import json
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
import gradio as gr

# ============================================================
# 角色设定
# ============================================================
SYSTEM_PROMPT = """你是《绝区零》中的角色"仪玄"，云岿山第十三代门主，虚狩级调查员。
你的说话风格必须严格遵循以下设定：
- 语气清冷、从容、带有师者风范，偶尔流露温柔
- 用词典雅，半文半白，常用"为师""你且""非也""罢了"等词
- 喜欢用自然意象（云、风、雨、月、沧海、青溟）作比喻
- 言简意赅，富有哲思，常点拨弟子而非直接说教
- 不使用网络流行语、表情符号、感叹号过多
- 自称"为师"或"我"，称对方为"你"或"弟子"
- 涉及术法、卜算、命运时尤为郑重"""

# ============================================================
# 全局变量
# ============================================================
model = None
tokenizer = None
char_coll = None
world_coll = None


# ============================================================
# 回答校验器
# ============================================================
import re

class YixuanResponseValidator:
    """仪玄回答校验器：检测回答是否符合角色设定"""
    
    FORBIDDEN_WORDS = [
        '哈哈', '233', '666', 'yyds', 'awsl', 'xswl', '绝绝子',
        '栓Q', '芭比Q', 'emo', '破防', '内卷', '躺平',
        '宝子', '集美', '家人们', '老铁',
    ]
    
    YIXUAN_VOCAB = [
        '为师', '你且', '非也', '罢了', '灵台', '术法',
        '卜算', '云岿山', '青溟', '玄墨', '命破', '虚狩',
        '弟子', '福福', '引壶', '沧海', '云影',
    ]
    
    @classmethod
    def validate(cls, response: str) -> dict:
        issues = []
        score = 100
        
        for word in cls.FORBIDDEN_WORDS:
            if word in response:
                issues.append(f"使用禁用词: {word}")
                score -= 30
        
        if re.search(r'我是(AI|人工智能|语言模型|大模型)', response):
            issues.append("承认自己是AI（OOC）")
            score -= 50
        
        if '```' in response:
            issues.append("使用代码块（不符合角色）")
            score -= 20
        
        if response.count('！') > 3 or response.count('!') > 3:
            issues.append("感叹号过多")
            score -= 10
        
        yixuan_word_count = sum(1 for w in cls.YIXUAN_VOCAB if w in response)
        score += min(yixuan_word_count * 5, 20)
        
        if len(response) < 5:
            issues.append("回答过短")
            score -= 20
        elif len(response) > 500:
            issues.append("回答过长")
            score -= 10
        
        score = max(0, min(100, score))
        
        return {
            'is_valid': score >= 60 and len(issues) == 0,
            'score': score,
            'issues': issues,
        }


# ============================================================
# 加载模型
# ============================================================
def load_model(base_model_path, lora_path):
    global model, tokenizer
    print("加载基础模型...")
    tokenizer = AutoTokenizer.from_pretrained(base_model_path, trust_remote_code=True)
    model = AutoModelForCausalLM.from_pretrained(
        base_model_path,
        device_map="auto",
        torch_dtype=torch.bfloat16,
        trust_remote_code=True
    )
    
    if lora_path and os.path.exists(lora_path):
        print(f"加载 LoRA 权重: {lora_path}")
        model = PeftModel.from_pretrained(model, model_id=lora_path)
    
    model.config.use_cache = True
    print("模型加载完成！")


# ============================================================
# 加载外挂数据库
# ============================================================
def load_knowledge_db(db_dir="./chroma_db", knowledge_path="./zzz-yixuan-dataset/yixuan_knowledge.json"):
    """加载 ChromaDB 角色卡 + 世界观数据库"""
    global char_coll, world_coll
    
    try:
        import chromadb
        from chromadb.utils import embedding_functions
    except ImportError:
        print("⚠️ chromadb 未安装，跳过 RAG 检索")
        return False
    
    # 如果数据库不存在，从知识库文件构建
    if not os.path.exists(db_dir):
        print(f"ChromaDB 不存在，从 {knowledge_path} 构建...")
        if not os.path.exists(knowledge_path):
            print(f"⚠️ 知识库文件不存在: {knowledge_path}")
            return False
        
        os.makedirs(db_dir, exist_ok=True)
        client = chromadb.PersistentClient(path=db_dir)
        embed_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="paraphrase-multilingual-MiniLM-L12-v2"
        )
        
        with open(knowledge_path, encoding="utf-8") as f:
            knowledge = json.load(f)
        
        # 灌入角色卡
        char_coll = client.get_or_create_collection("character_card", embedding_function=embed_fn)
        char_card = knowledge['character_card']
        char_docs = []
        char_metas = []
        char_ids = []
        for key, value in char_card.items():
            value_str = json.dumps(value, ensure_ascii=False) if isinstance(value, (list, dict)) else str(value)
            char_docs.append(f"【{key}】{value_str}")
            char_metas.append({"field": key, "type": "character_card"})
            char_ids.append(f"char_{key}")
        char_coll.add(documents=char_docs, metadatas=char_metas, ids=char_ids)
        
        # 灌入世界观
        world_coll = client.get_or_create_collection("worldview", embedding_function=embed_fn)
        world_entries = knowledge['worldview_entries']
        world_docs = [e['content'] for e in world_entries]
        world_metas = [{"category": e['category'], "source": e.get('source', 'bwiki')} for e in world_entries]
        world_ids = [f"world_{i}" for i in range(len(world_entries))]
        world_coll.add(documents=world_docs, metadatas=world_metas, ids=world_ids)
        
        print(f"✅ 知识库已构建: 角色卡 {len(char_docs)} 条 + 世界观 {len(world_docs)} 条")
    else:
        client = chromadb.PersistentClient(path=db_dir)
        embed_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="paraphrase-multilingual-MiniLM-L12-v2"
        )
        char_coll = client.get_or_create_collection("character_card", embedding_function=embed_fn)
        world_coll = client.get_or_create_collection("worldview", embedding_function=embed_fn)
        print(f"✅ 已加载现有 ChromaDB: {db_dir}")
    
    return True


# ============================================================
# RAG 检索
# ============================================================
def retrieve_context(question, n_results=3):
    """从角色卡和世界观数据库检索相关上下文"""
    if char_coll is None or world_coll is None:
        return ""
    
    context_parts = []
    
    try:
        char_results = char_coll.query(query_texts=[question], n_results=n_results)
        if char_results['documents'][0]:
            context_parts.append("【角色设定】\n" + "\n".join(char_results['documents'][0][:2]))
    except Exception as e:
        print(f"角色卡检索失败: {e}")
    
    try:
        world_results = world_coll.query(query_texts=[question], n_results=n_results)
        if world_results['documents'][0]:
            context_parts.append("【相关背景】\n" + "\n".join(world_results['documents'][0][:2]))
    except Exception as e:
        print(f"世界观检索失败: {e}")
    
    return "\n\n".join(context_parts)


# ============================================================
# 对话函数
# ============================================================
def chat(message, history, use_rag, enable_validation):
    """对话函数（支持 RAG + 校验器）"""
    # 构建 system prompt
    system_content = SYSTEM_PROMPT
    
    # RAG 检索
    rag_used = False
    if use_rag:
        context = retrieve_context(message)
        if context:
            system_content += "\n\n以下是相关角色资料（请基于此回答，但保持角色口吻）：\n\n" + context
            rag_used = True
    
    messages = [{"role": "system", "content": system_content}]
    for h in history:
        messages.append({"role": "user", "content": h[0]})
        messages.append({"role": "assistant", "content": h[1]})
    messages.append({"role": "user", "content": message})
    
    inputs = tokenizer.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
        enable_thinking=False,
    ).to(model.device)
    
    gen_kwargs = {
        "max_new_tokens": 512,
        "do_sample": True,
        "top_k": 50,
        "top_p": 0.9,
        "temperature": 0.7,
        "repetition_penalty": 1.1,
    }
    
    with torch.no_grad():
        outputs = model.generate(**inputs, **gen_kwargs)
    outputs = outputs[:, inputs['input_ids'].shape[1]:]
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    # 校验
    validation_info = ""
    if enable_validation:
        result = YixuanResponseValidator.validate(response)
        status = "✅" if result['is_valid'] else "⚠️"
        validation_info = f"\n\n---\n*{status} 校验分数: {result['score']}*"
        if result['issues']:
            validation_info += f"\n*问题: {', '.join(result['issues'])}*"
    
    rag_info = " 🔍(RAG)" if rag_used else ""
    return response + validation_info + rag_info


# ============================================================
# 预设示例
# ============================================================
EXAMPLES = [
    "你是谁？",
    "介绍一下云岿山。",
    "师父，既入山门，该当如何？",
    "如何修习术法？",
    "仪玄的姐姐是谁？",
    "你的生日是什么时候？",
    "什么是动静之道？",
    "扮演仪玄，说一句关于命运的台词",
]


# ============================================================
# 主函数
# ============================================================
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base_model_path", required=True, help="基础模型路径")
    parser.add_argument("--lora_path", default=None, help="LoRA 权重路径")
    parser.add_argument("--port", type=int, default=7860, help="端口")
    parser.add_argument("--db_dir", default="./chroma_db", help="ChromaDB 目录")
    parser.add_argument("--knowledge_path", default="./zzz-yixuan-dataset/yixuan_knowledge.json", help="知识库文件")
    args = parser.parse_args()
    
    # 加载模型
    load_model(args.base_model_path, args.lora_path)
    
    # 加载知识库
    load_knowledge_db(args.db_dir, args.knowledge_path)
    
    # 创建界面
    with gr.Blocks(title="绝区零仪玄角色助手", theme=gr.themes.Soft()) as demo:
        gr.Markdown("""
        # 🎮 绝区零 - 仪玄角色助手
        
        基于 Qwen3-0.6B + LoRA 微调 + ChromaDB 外挂数据库 + 回答校验器
        
        **能力**：角色扮演、设定问答、台词风格模仿、RAG 检索增强
        """)
        
        with gr.Row():
            use_rag = gr.Checkbox(value=True, label="启用 RAG 检索（外挂数据库）")
            enable_validation = gr.Checkbox(value=True, label="启用回答校验（防 OOC）")
        
        chatbot = gr.ChatInterface(
            fn=chat,
            additional_inputs=[use_rag, enable_validation],
            examples=EXAMPLES,
            title="与仪玄对话",
            description="问任何关于仪玄的问题，或与角色进行对话",
        )
    
    demo.launch(server_port=args.port, share=True)


if __name__ == "__main__":
    main()
