"""
生成模型预测结果，用于评估
用法：python generate_predictions.py --model_path ./output --base_model_path ./models/Qwen3 --test_dir ./eval --output predictions.json
"""
import json
import os
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel


SYSTEM_PROMPT = """你是《绝区零》中的角色"仪玄"，云岿山第十三代门主，虚狩级调查员。
你的说话风格必须严格遵循以下设定：
- 语气清冷、从容、带有师者风范，偶尔流露温柔
- 用词典雅，半文半白，常用"为师""你且""非也""罢了"等词
- 喜欢用自然意象（云、风、雨、月、沧海、青溟）作比喻
- 言简意赅，富有哲思，常点拨弟子而非直接说教
- 不使用网络流行语、表情符号、感叹号过多
- 自称"为师"或"我"，称对方为"你"或"弟子"
- 涉及术法、卜算、命运时尤为郑重"""


def load_model(base_model_path, lora_path):
    """加载基础模型 + LoRA 权重"""
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
    
    return model, tokenizer


def generate_answer(model, tokenizer, question, system_prompt=SYSTEM_PROMPT):
    """生成回答"""
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": question}
    ]
    inputs = tokenizer.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
        enable_thinking=False,
    ).to(model.device)
    
    gen_kwargs = {"max_new_tokens": 512, "do_sample": False, "top_k": 1}
    with torch.no_grad():
        outputs = model.generate(**inputs, **gen_kwargs)
        outputs = outputs[:, inputs['input_ids'].shape[1]:]
    return tokenizer.decode(outputs[0], skip_special_tokens=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base_model_path", required=True, help="基础模型路径")
    parser.add_argument("--lora_path", default=None, help="LoRA 权重路径")
    parser.add_argument("--test_dir", default="./eval", help="测试集目录")
    parser.add_argument("--output", default="predictions.json", help="输出文件")
    args = parser.parse_args()
    
    # 加载模型
    model, tokenizer = load_model(args.base_model_path, args.lora_path)
    
    # 加载测试集
    predictions = {}
    test_files = ["test_roleplay.json", "test_knowledge.json", "test_hallucination.json"]
    
    for test_file in test_files:
        test_path = os.path.join(args.test_dir, test_file)
        if not os.path.exists(test_path):
            continue
        
        with open(test_path, encoding="utf-8") as f:
            tests = json.load(f)
        
        print(f"\n处理 {test_file} ({len(tests)} 题)...")
        for i, test in enumerate(tests):
            qid = test["id"]
            question = test["question"]
            answer = generate_answer(model, tokenizer, question)
            predictions[qid] = answer
            
            if (i + 1) % 10 == 0:
                print(f"  进度: {i+1}/{len(tests)}")
    
    # 保存预测结果
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(predictions, f, ensure_ascii=False, indent=2)
    
    print(f"\n预测完成！共 {len(predictions)} 条")
    print(f"结果保存到: {args.output}")


if __name__ == "__main__":
    main()
