#!/usr/bin/env python3
"""
Higress AI Gateway - Interactive Testing Tool
Real AI responses without CORS issues!
"""
import requests
import json
import sys
from datetime import datetime

# AI Gateway Configuration
GATEWAY_URL = "http://192.168.49.1:8889/compatible-mode/v1/chat/completions"
API_KEY = "sk-49dc7c806e0a4ad08f076b22c4fbee86"

MODELS = {
    "1": ("qwen-turbo", "Fast & Efficient"),
    "2": ("qwen-max", "Best Quality"),
    "3": ("qwen-plus", "Balanced Performance")
}

def print_header():
    print("=" * 60)
    print("🎮 HIGRESS AI GATEWAY - INTERACTIVE TEST")
    print("=" * 60)
    print("✅ Real AI responses (not simulated)")
    print("✅ Multiple Qwen models available")
    print("✅ Usage statistics included")
    print("-" * 60)

def choose_model():
    print("\n📋 Available Models:")
    for key, (model, desc) in MODELS.items():
        print(f"  {key}. {model} - {desc}")
    
    while True:
        choice = input("\nSelect model (1-3) [default: 1]: ").strip()
        if not choice:
            choice = "1"
        if choice in MODELS:
            return MODELS[choice][0]
        print("❌ Invalid choice. Please select 1, 2, or 3.")

def get_message():
    print("\n💬 Enter your message:")
    print("(Type 'quit' to exit, 'demo' for sample messages)")
    
    message = input("You: ").strip()
    
    if message.lower() == 'quit':
        return None
    elif message.lower() == 'demo':
        demos = [
            "Hello! Can you tell me a fun fact about AI?",
            "Explain quantum computing in simple terms",
            "Write a short poem about technology",
            "What are the benefits of using an AI Gateway?"
        ]
        print("\n🎯 Sample messages:")
        for i, demo in enumerate(demos, 1):
            print(f"  {i}. {demo}")
        
        choice = input("\nSelect demo (1-4) or type your own: ").strip()
        if choice in ['1', '2', '3', '4']:
            return demos[int(choice) - 1]
        else:
            return choice if choice else demos[0]
    
    return message

def get_max_tokens():
    while True:
        try:
            tokens = input("Max tokens [default: 100]: ").strip()
            if not tokens:
                return 100
            tokens = int(tokens)
            if 1 <= tokens <= 2000:
                return tokens
            print("❌ Please enter a number between 1 and 2000.")
        except ValueError:
            print("❌ Please enter a valid number.")

def test_ai_gateway(model, message, max_tokens):
    print(f"\n🚀 Sending to AI Gateway...")
    print(f"Model: {model}")
    print(f"Message: {message}")
    print(f"Max tokens: {max_tokens}")
    print("-" * 40)
    
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": message}],
        "max_tokens": max_tokens
    }
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    
    try:
        response = requests.post(GATEWAY_URL, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            
            # Extract AI response
            ai_response = data.get('choices', [{}])[0].get('message', {}).get('content', 'No response')
            usage = data.get('usage', {})
            model_used = data.get('model', model)
            
            # Display results
            print("🤖 AI Response:")
            print("=" * 40)
            print(ai_response)
            print("=" * 40)
            
            print(f"\n📊 Usage Statistics:")
            print(f"Model: {model_used}")
            print(f"Prompt tokens: {usage.get('prompt_tokens', 0)}")
            print(f"Completion tokens: {usage.get('completion_tokens', 0)}")
            print(f"Total tokens: {usage.get('total_tokens', 0)}")
            print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            return True
            
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection Error: {e}")
        print("\n🔧 Troubleshooting:")
        print("1. Check if proxy server is running: ps aux | grep qwen-proxy")
        print("2. Restart if needed: python3 qwen-proxy.py 8889 &")
        return False

def main():
    print_header()
    
    try:
        while True:
            # Get test parameters
            model = choose_model()
            message = get_message()
            
            if message is None:  # User wants to quit
                print("\n👋 Thanks for testing your AI Gateway!")
                break
                
            if not message.strip():
                print("❌ Please enter a message.")
                continue
                
            max_tokens = get_max_tokens()
            
            # Test AI Gateway
            success = test_ai_gateway(model, message, max_tokens)
            
            if success:
                print("\n✅ Test completed successfully!")
            else:
                print("\n❌ Test failed. Check your configuration.")
            
            # Continue testing?
            continue_test = input("\n🔄 Test again? (y/n) [default: y]: ").strip().lower()
            if continue_test in ['n', 'no']:
                break
                
    except KeyboardInterrupt:
        print("\n\n👋 Goodbye!")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    main() 