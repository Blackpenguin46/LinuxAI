#!/usr/bin/env python3
"""
Main application for LLM-powered Linux AI
Integrates NLP frontend with command orchestrator for complete natural language shell experience
"""

import sys
import os
from nlp_frontend import NLPFrontend
from command_orchestrator import CommandOrchestrator
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LinuxAI:
    def __init__(self):
        self.nlp = NLPFrontend(model="llama3.2:1b")
        self.orchestrator = CommandOrchestrator()
        self.session_active = True
        
    def display_banner(self):
        """Display startup banner"""
        print("=" * 60)
        print("    🤖 LLM-powered Linux AI - Natural Language Shell")
        print("=" * 60)
        print("Talk to your Linux system in natural language!")
        print()
        print("Commands:")
        print("  exit, quit      - Exit the application")
        print("  help           - Show this help message")
        print("  history        - Show conversation history")
        print("  clear          - Clear command history")
        print("  status         - Check system status")
        print()
        print("Examples:")
        print('  "show me my current directory"')
        print('  "list all files in this folder"')
        print('  "check how much disk space I have"')
        print('  "find all Python files"')
        print("-" * 60)
    
    def check_system_status(self):
        """Check if all required components are available"""
        print("Checking system status...")
        
        # Check Ollama
        if self.nlp.check_ollama_status():
            print("✅ Ollama service: Online")
        else:
            print("❌ Ollama service: Offline")
            print("   Please ensure Ollama is installed and running:")
            print("   1. Install: curl -fsSL https://ollama.com/install.sh | sh")
            print("   2. Start: ollama serve")
            print("   3. Pull model: ollama pull llama3.2:1b")
            return False
        
        # Check model availability
        try:
            test_response = self.nlp.send_prompt_to_llm("test")
            if test_response:
                print(f"✅ LLM model ({self.nlp.model}): Available")
            else:
                print(f"❌ LLM model ({self.nlp.model}): Not responding")
                return False
        except Exception as e:
            print(f"❌ LLM model test failed: {e}")
            return False
        
        print("✅ Command orchestrator: Ready")
        print("✅ Security sandbox: Enabled" if self.orchestrator.sandbox_enabled else "⚠️  Security sandbox: Disabled")
        print()
        return True
    
    def process_special_commands(self, user_input: str) -> bool:
        """Handle special commands that don't require LLM processing"""
        command = user_input.lower().strip()
        
        if command in ['exit', 'quit']:
            print("Goodbye! 👋")
            self.session_active = False
            return True
        
        elif command == 'help':
            self.display_banner()
            return True
        
        elif command == 'history':
            self.show_history()
            return True
        
        elif command == 'clear':
            self.orchestrator.clear_history()
            self.nlp.conversation_history.clear()
            print("History cleared.")
            return True
        
        elif command == 'status':
            self.check_system_status()
            return True
        
        return False
    
    def show_history(self):
        """Display conversation and command history"""
        print("\n--- Conversation History ---")
        if self.nlp.conversation_history:
            for i, entry in enumerate(self.nlp.conversation_history[-10:], 1):
                print(f"\n{i}. User: {entry['user_input']}")
                result = entry['parsed_result']
                if result['type'] == 'command':
                    print(f"   Generated: {result['command']}")
                else:
                    print(f"   Result: {result}")
        else:
            print("No conversation history yet.")
        
        print("\n--- Command Execution History ---")
        cmd_history = self.orchestrator.get_command_history()
        if cmd_history:
            for i, entry in enumerate(cmd_history, 1):
                status = "✅" if entry.get("success", False) else "❌"
                print(f"{i}. {status} {entry['command']}")
        else:
            print("No command execution history yet.")
    
    def confirm_command_execution(self, command: str) -> bool:
        """Ask user for confirmation before executing command"""
        print(f"\nGenerated command: {command}")
        while True:
            response = input("Execute this command? (y/n/s): ").lower().strip()
            if response == 'y':
                return True
            elif response == 'n':
                return False
            elif response == 's':
                print("Command execution skipped.")
                return False
            else:
                print("Please enter 'y' for yes, 'n' for no, or 's' to skip.")
    
    def execute_command_safely(self, command: str):
        """Execute command with proper error handling and user feedback"""
        print(f"Executing: {command}")
        result = self.orchestrator.execute_shell_command(command)
        
        if result.get("blocked"):
            print(f"🚫 Command blocked: {result['error']}")
            return
        
        if result.get("timeout"):
            print("⏰ Command timed out")
            return
        
        if result["success"]:
            print("✅ Command executed successfully")
            if result["output"].strip():
                print("\nOutput:")
                print(result["output"])
        else:
            print(f"❌ Command failed (exit code: {result['return_code']})")
            if result["error"].strip():
                print("Error:")
                print(result["error"])
    
    def run(self):
        """Main application loop"""
        self.display_banner()
        
        # Check system status on startup
        if not self.check_system_status():
            print("⚠️  System not ready. Please fix the issues above and try again.")
            return
        
        print("System ready! You can now interact with your Linux system using natural language.")
        print("Type 'help' for available commands.\n")
        
        while self.session_active:
            try:
                user_input = input("🤖 LinuxAI> ").strip()
                
                if not user_input:
                    continue
                
                # Handle special commands
                if self.process_special_commands(user_input):
                    continue
                
                # Process natural language input
                print("🧠 Processing natural language input...")
                result = self.nlp.process_input(user_input)
                
                if result["type"] == "error":
                    print(f"❌ Error: {result['message']}")
                
                elif result["type"] == "clarification":
                    print(f"🤔 {result['message']}")
                
                elif result["type"] == "blocked":
                    print(f"🚫 {result['message']}")
                
                elif result["type"] == "command":
                    command = result["command"]
                    
                    # Check if command requires confirmation
                    cmd_name = command.split()[0] if command.split() else ""
                    validation = self.orchestrator.validate_command(cmd_name, command.split()[1:])
                    
                    if validation.get("requires_confirmation", False):
                        if not self.confirm_command_execution(command):
                            continue
                    
                    # Execute the command
                    self.execute_command_safely(command)
                
                else:
                    print(f"🤷 Unexpected result type: {result}")
                    
            except KeyboardInterrupt:
                print("\n\nExiting... 👋")
                break
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                print(f"❌ An unexpected error occurred: {e}")

def main():
    """Entry point for the application"""
    try:
        app = LinuxAI()
        app.run()
    except Exception as e:
        logger.error(f"Failed to start LinuxAI: {e}")
        print(f"❌ Failed to start LinuxAI: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()