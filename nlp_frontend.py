#!/usr/bin/env python3
"""
Natural Language Processor Frontend for LLM-powered Linux Distribution
Handles user input and interfaces with Ollama for LLM processing
"""

import json
import requests
import subprocess
import sys
from typing import Dict, Any, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class NLPFrontend:
    def __init__(self, ollama_host: str = "http://localhost:11434", model: str = "llama2"):
        self.ollama_host = ollama_host
        self.model = model
        self.conversation_history = []
        
    def check_ollama_status(self) -> bool:
        """Check if Ollama service is running and accessible"""
        try:
            response = requests.get(f"{self.ollama_host}/api/tags")
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def send_prompt_to_llm(self, prompt: str) -> Optional[str]:
        """Send user input to LLM via Ollama and return response"""
        system_prompt = """You are an AI assistant integrated into a Linux operating system. 
Your primary task is to interpret natural language commands and convert them into appropriate shell commands.

Rules:
1. Return ONLY the shell command, no explanations
2. If the request is unclear or potentially dangerous, ask for clarification
3. For complex tasks, break them down into safe, simple commands
4. Always consider security and never suggest commands that could harm the system

Examples:
User: "show me my current directory"
Response: pwd

User: "list all files"  
Response: ls -la

User: "create a folder called test"
Response: mkdir test

User: "check disk usage"
Response: df -h
"""
        
        try:
            payload = {
                "model": self.model,
                "prompt": f"{system_prompt}\n\nUser: {prompt}\nResponse:",
                "stream": False
            }
            
            response = requests.post(
                f"{self.ollama_host}/api/generate",
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("response", "").strip()
            else:
                logger.error(f"Ollama API error: {response.status_code}")
                return None
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to connect to Ollama: {e}")
            return None
    
    def parse_llm_response(self, response: str) -> Dict[str, Any]:
        """Parse LLM response and extract command information"""
        if not response:
            return {"type": "error", "message": "No response from LLM"}
        
        # Check if response contains a question or clarification request
        if any(indicator in response.lower() for indicator in ["?", "clarify", "unclear", "specify"]):
            return {"type": "clarification", "message": response}
        
        # Clean up markdown code blocks and extract command
        cleaned_response = response.strip()
        
        # Remove markdown code block markers
        if cleaned_response.startswith('```'):
            lines = cleaned_response.split('\n')
            # Remove first line (```) and last line (```)
            if len(lines) > 2 and lines[-1].strip() == '```':
                lines = lines[1:-1]
            elif len(lines) > 1:
                lines = lines[1:]  # Just remove first line
            cleaned_response = '\n'.join(lines).strip()
        
        # Extract shell command (remove any potential explanations)
        lines = cleaned_response.split('\n')
        command = lines[0].strip()
        
        # Remove any remaining markdown or language indicators
        if command.startswith('bash') or command.startswith('sh'):
            command = ' '.join(command.split()[1:])
        
        # Basic safety check for dangerous commands
        dangerous_patterns = [
            'rm -rf /', 'rm -rf *', 'mkfs', 'dd if=', 'sudo rm -rf /',
            '> /dev/sda', 'format c:', 'fdisk /dev/sda', 'chmod 777 /'
        ]
        
        if any(pattern in command.lower() for pattern in dangerous_patterns):
            return {"type": "blocked", "message": f"Command blocked for safety: {command}"}
        
        return {"type": "command", "command": command}
    
    def process_input(self, user_input: str) -> Dict[str, Any]:
        """Main processing function for user input"""
        if not user_input.strip():
            return {"type": "error", "message": "Empty input"}
        
        # Check Ollama availability
        if not self.check_ollama_status():
            return {"type": "error", "message": "Ollama service not available"}
        
        # Send to LLM
        llm_response = self.send_prompt_to_llm(user_input)
        if not llm_response:
            return {"type": "error", "message": "Failed to get response from LLM"}
        
        # Parse response
        parsed = self.parse_llm_response(llm_response)
        
        # Store in conversation history
        self.conversation_history.append({
            "user_input": user_input,
            "llm_response": llm_response,
            "parsed_result": parsed
        })
        
        return parsed

def main():
    """Interactive CLI for testing the NLP frontend"""
    nlp = NLPFrontend()
    
    print("LLM-powered Linux AI - Natural Language Interface")
    print("Type 'exit' to quit, 'history' to see conversation history")
    print("-" * 50)
    
    while True:
        try:
            user_input = input("\n> ").strip()
            
            if user_input.lower() == 'exit':
                break
            elif user_input.lower() == 'history':
                if nlp.conversation_history:
                    for i, entry in enumerate(nlp.conversation_history[-5:], 1):
                        print(f"\n{i}. User: {entry['user_input']}")
                        print(f"   Result: {entry['parsed_result']}")
                else:
                    print("No conversation history yet.")
                continue
            
            result = nlp.process_input(user_input)
            
            if result["type"] == "command":
                print(f"Generated command: {result['command']}")
                confirm = input("Execute this command? (y/n): ").lower()
                if confirm == 'y':
                    print("Command would be executed by orchestrator...")
            elif result["type"] == "clarification":
                print(f"LLM response: {result['message']}")
            elif result["type"] == "blocked":
                print(f"Safety block: {result['message']}")
            else:
                print(f"Error: {result['message']}")
                
        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()