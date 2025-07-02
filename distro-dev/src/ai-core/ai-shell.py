#!/usr/bin/env python3
"""
LinuxAI Shell - AI-Enhanced Command Line Interface
Core component of LinuxAI distribution that provides natural language system control
"""

import os
import sys
import json
import asyncio
import logging
from typing import Dict, Any, Optional
from pathlib import Path

# LinuxAI system imports
from ai_core.nlp_processor import NLPProcessor
from ai_core.command_executor import SystemCommandExecutor
from ai_core.voice_interface import VoiceInterface
from ai_core.system_monitor import SystemMonitor

class LinuxAIShell:
    """AI-enhanced shell for LinuxAI distribution"""
    
    def __init__(self):
        self.config_path = Path("/etc/ai-system/shell.conf")
        self.model_path = Path("/usr/lib/ai-system/models")
        self.log_path = Path("/var/log/ai-system/shell.log")
        
        # Initialize logging
        self.setup_logging()
        
        # Core AI components
        self.nlp = NLPProcessor(model_path=self.model_path)
        self.executor = SystemCommandExecutor()
        self.voice = VoiceInterface()
        self.monitor = SystemMonitor()
        
        # Shell state
        self.session_active = True
        self.voice_enabled = True
        self.current_user = os.getenv("USER", "unknown")
        self.hostname = os.uname().nodename
        
        self.logger.info(f"LinuxAI Shell initialized for user: {self.current_user}")
    
    def setup_logging(self):
        """Configure logging for AI shell"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_path),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger("ai-shell")
    
    def display_banner(self):
        """Display LinuxAI shell banner"""
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║                     LinuxAI Shell v0.1.0                    ║")
        print("║              AI-Powered Linux Distribution                   ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        print()
        print("🤖 Welcome to LinuxAI! Control your system with natural language.")
        print("💬 Type commands in plain English or use traditional shell syntax")
        print("🎤 Voice commands available (say 'hey linux' to activate)")
        print("📋 Type 'help' for available commands, 'exit' to quit")
        print()
        
        # Display system status
        status = self.monitor.get_system_status()
        print(f"🖥️  System: {status['hostname']} | "
              f"💾 RAM: {status['memory_percent']:.1f}% | "
              f"💽 Disk: {status['disk_percent']:.1f}%")
        print()
    
    def get_prompt(self) -> str:
        """Generate dynamic AI shell prompt"""
        cwd = os.getcwd()
        if cwd == os.path.expanduser("~"):
            cwd_display = "~"
        else:
            cwd_display = os.path.basename(cwd)
        
        # Color codes for prompt
        blue = "\033[94m"
        green = "\033[92m"
        reset = "\033[0m"
        
        return f"{blue}{self.current_user}@{self.hostname}{reset}:{green}{cwd_display}{reset}$ "
    
    async def process_input(self, user_input: str) -> Dict[str, Any]:
        """Process user input through AI system"""
        try:
            # Check for built-in commands first
            if user_input.lower() in ['exit', 'quit']:
                self.session_active = False
                return {"type": "exit", "message": "Goodbye!"}
            
            if user_input.lower() == 'help':
                return {"type": "help", "message": self.get_help_text()}
            
            if user_input.lower() == 'status':
                status = self.monitor.get_detailed_status()
                return {"type": "status", "data": status}
            
            # Process through AI NLP system
            self.logger.info(f"Processing input: {user_input[:50]}...")
            
            # Natural language processing
            nlp_result = await self.nlp.process_command(user_input)
            
            if nlp_result["type"] == "system_command":
                # Execute system command through secure executor
                exec_result = await self.executor.execute_command(
                    nlp_result["command"],
                    user=self.current_user,
                    safe_mode=True
                )
                return exec_result
            
            elif nlp_result["type"] == "conversation":
                # Handle conversational AI responses
                return nlp_result
            
            elif nlp_result["type"] == "clarification":
                # Ask for clarification
                return nlp_result
            
            else:
                return {"type": "error", "message": "Could not understand the request"}
                
        except Exception as e:
            self.logger.error(f"Error processing input: {e}")
            return {"type": "error", "message": f"System error: {str(e)}"}
    
    def get_help_text(self) -> str:
        """Return help text for AI shell"""
        return """
LinuxAI Shell Help:

🎯 Natural Language Commands:
  "install docker"              - Install software packages
  "show me running processes"    - Display system information  
  "create a new user called bob" - User management
  "backup my home directory"     - File operations
  "check system performance"     - System monitoring
  "connect to wifi network"      - Network configuration

🔧 Traditional Commands:
  All standard Linux commands are supported (ls, cd, grep, etc.)

🎤 Voice Commands:
  Say "hey linux" followed by your command
  Example: "hey linux, show me disk usage"

🛠️ System Commands:
  help     - Show this help message
  status   - Display detailed system status
  exit     - Exit AI shell

💡 Tips:
  - Be specific with your requests
  - You can mix natural language with technical terms
  - The AI learns from your usage patterns
  - All commands are logged for security
        """
    
    async def handle_voice_input(self):
        """Handle voice input in background"""
        while self.session_active and self.voice_enabled:
            try:
                voice_input = await self.voice.listen_for_wake_word()
                if voice_input:
                    print(f"\n🎤 Voice: {voice_input}")
                    result = await self.process_input(voice_input)
                    self.display_result(result)
                    print(self.get_prompt(), end="", flush=True)
            except Exception as e:
                self.logger.error(f"Voice input error: {e}")
            
            await asyncio.sleep(0.1)
    
    def display_result(self, result: Dict[str, Any]):
        """Display command execution results"""
        if result["type"] == "success":
            if "output" in result and result["output"]:
                print(result["output"])
        
        elif result["type"] == "error":
            print(f"❌ Error: {result['message']}")
        
        elif result["type"] == "clarification":
            print(f"🤔 {result['message']}")
        
        elif result["type"] == "status":
            self.display_system_status(result["data"])
        
        elif result["type"] == "help":
            print(result["message"])
        
        elif result["type"] == "confirmation":
            response = input(f"⚠️  {result['message']} (y/N): ")
            return response.lower().startswith('y')
    
    def display_system_status(self, status: Dict[str, Any]):
        """Display formatted system status"""
        print("📊 System Status:")
        print(f"  🖥️  Hostname: {status['hostname']}")
        print(f"  ⏰ Uptime: {status['uptime']}")
        print(f"  💾 Memory: {status['memory_used']:.1f}GB / {status['memory_total']:.1f}GB ({status['memory_percent']:.1f}%)")
        print(f"  💽 Disk: {status['disk_used']:.1f}GB / {status['disk_total']:.1f}GB ({status['disk_percent']:.1f}%)")
        print(f"  🔥 CPU: {status['cpu_percent']:.1f}%")
        print(f"  🌡️  Temperature: {status.get('temperature', 'N/A')}")
    
    async def run(self):
        """Main shell loop"""
        self.display_banner()
        
        # Start voice input handler
        voice_task = asyncio.create_task(self.handle_voice_input())
        
        try:
            while self.session_active:
                try:
                    # Display prompt and get input
                    user_input = input(self.get_prompt()).strip()
                    
                    if not user_input:
                        continue
                    
                    # Process input
                    result = await self.process_input(user_input)
                    
                    # Display result
                    if result["type"] == "exit":
                        print(result["message"])
                        break
                    else:
                        self.display_result(result)
                
                except KeyboardInterrupt:
                    print("\n\nUse 'exit' to quit the AI shell.")
                    continue
                
                except EOFError:
                    print("\nGoodbye!")
                    break
        
        finally:
            # Cleanup
            voice_task.cancel()
            self.logger.info("AI Shell session ended")

def main():
    """Entry point for LinuxAI shell"""
    try:
        shell = LinuxAIShell()
        asyncio.run(shell.run())
    except Exception as e:
        print(f"Failed to start LinuxAI shell: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()