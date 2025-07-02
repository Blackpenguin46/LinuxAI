#!/usr/bin/env python3
"""
Demo script to test Linux AI functionality without requiring Ollama
Shows how natural language would be processed and executed
"""

from command_orchestrator import CommandOrchestrator

def simulate_nlp_processing(user_input: str) -> str:
    """Simulate what the LLM would do - map natural language to commands"""
    
    # Simple pattern matching to demonstrate the concept
    input_lower = user_input.lower()
    
    if "current directory" in input_lower or "where am i" in input_lower:
        return "pwd"
    elif "list files" in input_lower or "show files" in input_lower:
        return "ls -la"
    elif "disk space" in input_lower or "disk usage" in input_lower:
        return "df -h"
    elif "who am i" in input_lower or "current user" in input_lower:
        return "whoami"
    elif "running processes" in input_lower or "show processes" in input_lower:
        return "ps aux | head -10"
    elif "system info" in input_lower or "system information" in input_lower:
        return "uname -a"
    elif "python files" in input_lower:
        return "find . -name '*.py' -type f"
    elif "memory usage" in input_lower:
        return "free -h"
    else:
        return None

def main():
    print("🤖 Linux AI Demo - Natural Language Command Processing")
    print("=" * 60)
    print("This demonstrates how the system would work with full LLM integration")
    print("Type 'exit' to quit\n")
    
    orchestrator = CommandOrchestrator()
    
    # Example natural language inputs
    test_phrases = [
        "show me my current directory",
        "list all files in this folder", 
        "check how much disk space I have",
        "find all Python files",
        "who am I logged in as",
        "show me running processes",
        "what's my system information"
    ]
    
    print("Demo with example phrases:")
    print("-" * 40)
    
    for phrase in test_phrases:
        print(f"\n🗣️  User: \"{phrase}\"")
        
        # Simulate LLM processing
        command = simulate_nlp_processing(phrase)
        
        if command:
            print(f"🧠 Generated command: {command}")
            
            # Execute through orchestrator
            result = orchestrator.execute_shell_command(command)
            
            if result['blocked']:
                print(f"🚫 Command blocked: {result['error']}")
            elif result['success']:
                print("✅ Executed successfully")
                output = result['output'].strip()
                if output:
                    # Limit output for demo
                    lines = output.split('\n')
                    if len(lines) > 3:
                        print(f"📄 Output (first 3 lines):")
                        for line in lines[:3]:
                            print(f"   {line}")
                        print(f"   ... ({len(lines)-3} more lines)")
                    else:
                        print(f"📄 Output: {output}")
            else:
                print(f"❌ Command failed: {result['error']}")
        else:
            print("🤔 Could not understand the request")
        
        print("-" * 40)
    
    # Interactive mode
    print("\nInteractive mode (enter natural language commands):")
    
    while True:
        try:
            user_input = input("\n🤖 LinuxAI> ").strip()
            
            if user_input.lower() in ['exit', 'quit']:
                print("Goodbye! 👋")
                break
                
            if not user_input:
                continue
                
            command = simulate_nlp_processing(user_input)
            
            if command:
                print(f"🧠 Generated command: {command}")
                confirm = input("Execute this command? (y/n): ").lower()
                
                if confirm == 'y':
                    result = orchestrator.execute_shell_command(command)
                    
                    if result['blocked']:
                        print(f"🚫 Command blocked: {result['error']}")
                    elif result['success']:
                        print("✅ Executed successfully")
                        if result['output'].strip():
                            print(f"📄 Output:\n{result['output']}")
                    else:
                        print(f"❌ Command failed: {result['error']}")
                else:
                    print("Command execution cancelled.")
            else:
                print("🤔 Sorry, I don't understand that request yet.")
                print("Try phrases like: 'show current directory', 'list files', 'check disk space'")
                
        except KeyboardInterrupt:
            print("\n\nGoodbye! 👋")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()