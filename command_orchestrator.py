#!/usr/bin/env python3
"""
Command Orchestrator for LLM-powered Linux Distribution
Handles secure execution of LLM-generated commands with logging and sandboxing
"""

import subprocess
import logging
import json
import os
import pwd
import grp
import shlex
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple
from pathlib import Path
import tempfile

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CommandOrchestrator:
    def __init__(self, log_file: str = "/tmp/llm_commands.log", sandbox_enabled: bool = True):
        self.log_file = log_file
        self.sandbox_enabled = sandbox_enabled
        self.command_history = []
        self.setup_logging()
        
        # Define whitelisted commands for safety
        self.safe_commands = {
            'ls', 'pwd', 'whoami', 'date', 'uptime', 'df', 'free', 'ps',
            'cat', 'head', 'tail', 'grep', 'find', 'locate', 'which',
            'echo', 'wc', 'sort', 'uniq', 'history', 'id', 'groups',
            'uname', 'hostname', 'env', 'printenv', 'mount', 'lsblk',
            'lscpu', 'lsmem', 'lsusb', 'lspci', 'systemctl status',
            'journalctl', 'dmesg', 'netstat', 'ss', 'ip', 'ping',
            'nslookup', 'dig', 'wget', 'curl', 'cd', 'tree', 'less',
            'more', 'top', 'htop', 'iotop', 'iostat', 'vmstat',
            'lsof', 'du', 'tar', 'gzip', 'gunzip', 'zip', 'unzip'
        }
        
        # Commands that require user confirmation
        self.confirmation_required = {
            'mkdir', 'rmdir', 'touch', 'cp', 'mv', 'ln', 'chmod',
            'chown', 'sudo', 'su', 'apt', 'yum', 'dnf', 'pacman',
            'git', 'docker', 'systemctl', 'service', 'killall',
            'npm', 'pip', 'pip3', 'python', 'python3', 'node',
            'make', 'cmake', 'gcc', 'g++', 'javac', 'java',
            'ssh', 'scp', 'rsync', 'mount', 'umount', 'crontab'
        }
        
        # Blocked commands for security
        self.blocked_commands = {
            'rm', 'dd', 'mkfs', 'fdisk', 'parted', 'format',
            'shutdown', 'reboot', 'halt', 'init', 'telinit'
        }
    
    def setup_logging(self):
        """Setup command execution logging"""
        log_dir = os.path.dirname(self.log_file)
        os.makedirs(log_dir, exist_ok=True)
        
        # Setup file handler for command logging
        self.command_logger = logging.getLogger('command_executor')
        handler = logging.FileHandler(self.log_file)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.command_logger.addHandler(handler)
        self.command_logger.setLevel(logging.INFO)
    
    def parse_command(self, command: str) -> Tuple[str, List[str]]:
        """Parse command string into command and arguments"""
        try:
            parts = shlex.split(command.strip())
            if not parts:
                return "", []
            return parts[0], parts[1:]
        except ValueError as e:
            logger.error(f"Failed to parse command: {command}, error: {e}")
            return "", []
    
    def validate_command(self, command: str, args: List[str]) -> Dict[str, Any]:
        """Validate command for security and safety"""
        full_command = f"{command} {' '.join(args)}".strip()
        
        # Check for blocked commands
        if command in self.blocked_commands:
            return {
                "allowed": False,
                "reason": f"Command '{command}' is blocked for security",
                "requires_confirmation": False
            }
        
        # Check for dangerous patterns
        dangerous_patterns = [
            '> /dev/', '< /dev/', 'rm -rf /', '&& rm -rf', '; rm -rf',
            'chmod 777 /', 'chmod 666 /', '> /etc/passwd', '> /etc/shadow',
            'sudo rm -rf', 'eval', 'exec'
        ]
        
        for pattern in dangerous_patterns:
            if pattern in full_command.lower():
                return {
                    "allowed": False,
                    "reason": f"Command contains dangerous pattern: {pattern}",
                    "requires_confirmation": False
                }
        
        # Check if confirmation required
        requires_confirmation = command in self.confirmation_required
        if requires_confirmation:
            return {
                "allowed": True,
                "reason": "Command requires user confirmation",
                "requires_confirmation": True
            }
        
        # Check if command is in safe list
        if command in self.safe_commands or full_command in self.safe_commands:
            return {
                "allowed": True,
                "reason": "Command is in safe list",
                "requires_confirmation": False
            }
        
        # Default: require confirmation for unknown commands
        return {
            "allowed": True,
            "reason": "Unknown command, requires confirmation",
            "requires_confirmation": True
        }
    
    def create_sandbox_environment(self) -> Dict[str, str]:
        """Create a restricted environment for command execution"""
        if not self.sandbox_enabled:
            return os.environ.copy()
        
        # Create minimal environment
        safe_env = {
            'PATH': '/usr/local/bin:/usr/bin:/bin',
            'HOME': os.path.expanduser('~'),
            'USER': os.getenv('USER', 'unknown'),
            'SHELL': '/bin/bash',
            'TERM': os.getenv('TERM', 'xterm'),
            'LANG': os.getenv('LANG', 'en_US.UTF-8'),
            'PWD': os.getcwd()
        }
        
        return safe_env
    
    def execute_shell_command(self, command: str, timeout: int = 30) -> Dict[str, Any]:
        """Execute shell command with logging and sandboxing"""
        cmd_parts = self.parse_command(command)
        if not cmd_parts[0]:
            return {
                "success": False,
                "output": "",
                "error": "Invalid command format",
                "return_code": -1
            }
        
        cmd_name, cmd_args = cmd_parts
        validation = self.validate_command(cmd_name, cmd_args)
        
        # Log the attempt
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "command": command,
            "validation": validation,
            "executed": False
        }
        
        if not validation["allowed"]:
            log_entry["result"] = "blocked"
            self.command_logger.warning(f"Blocked command: {command} - {validation['reason']}")
            self.command_history.append(log_entry)
            return {
                "success": False,
                "output": "",
                "error": validation["reason"],
                "return_code": -1,
                "blocked": True
            }
        
        try:
            # Create sandbox environment
            env = self.create_sandbox_environment()
            
            # Execute command
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env,
                cwd=os.getcwd()
            )
            
            log_entry["executed"] = True
            log_entry["return_code"] = result.returncode
            log_entry["success"] = result.returncode == 0
            
            if result.returncode == 0:
                self.command_logger.info(f"Executed successfully: {command}")
            else:
                self.command_logger.warning(f"Command failed: {command} (exit code: {result.returncode})")
            
            self.command_history.append(log_entry)
            
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr,
                "return_code": result.returncode,
                "blocked": False
            }
            
        except subprocess.TimeoutExpired:
            error_msg = f"Command timed out after {timeout} seconds"
            self.command_logger.error(f"Timeout: {command}")
            log_entry["result"] = "timeout"
            self.command_history.append(log_entry)
            
            return {
                "success": False,
                "output": "",
                "error": error_msg,
                "return_code": -1,
                "timeout": True
            }
            
        except Exception as e:
            error_msg = f"Execution error: {str(e)}"
            self.command_logger.error(f"Error executing {command}: {e}")
            log_entry["result"] = "error"
            log_entry["error"] = str(e)
            self.command_history.append(log_entry)
            
            return {
                "success": False,
                "output": "",
                "error": error_msg,
                "return_code": -1
            }
    
    def get_command_history(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent command execution history"""
        return self.command_history[-limit:]
    
    def clear_history(self):
        """Clear command history"""
        self.command_history.clear()
        self.command_logger.info("Command history cleared")

def main():
    """Interactive CLI for testing the command orchestrator"""
    orchestrator = CommandOrchestrator()
    
    print("LLM-powered Linux AI - Command Orchestrator")
    print("Type 'exit' to quit, 'history' to see execution history")
    print("-" * 50)
    
    while True:
        try:
            command = input("\nEnter command to execute: ").strip()
            
            if command.lower() == 'exit':
                break
            elif command.lower() == 'history':
                history = orchestrator.get_command_history()
                if history:
                    for i, entry in enumerate(history, 1):
                        status = "✓" if entry.get("success", False) else "✗"
                        print(f"{i}. {status} {entry['command']} ({entry['timestamp']})")
                else:
                    print("No command history yet.")
                continue
            elif command.lower() == 'clear':
                orchestrator.clear_history()
                print("History cleared.")
                continue
            
            if not command:
                continue
            
            print(f"Executing: {command}")
            result = orchestrator.execute_shell_command(command)
            
            if result.get("blocked"):
                print(f"❌ Blocked: {result['error']}")
            elif result["success"]:
                print(f"✅ Success (exit code: {result['return_code']})")
                if result["output"]:
                    print("Output:")
                    print(result["output"])
            else:
                print(f"❌ Failed (exit code: {result['return_code']})")
                if result["error"]:
                    print("Error:")
                    print(result["error"])
                    
        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()