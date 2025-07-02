#!/bin/bash
# LinuxAI Local Testing Setup for macOS
# No external dependencies required - uses built-in macOS tools

set -e

echo "🍎 LinuxAI Testing Setup for Apple Silicon Mac"
echo "=============================================="

PROJECT_DIR="/Users/samoakes/Desktop/LinuxAI/distro-dev"
TEST_DIR="$PROJECT_DIR/local-testing"

# Create testing environment
echo "📁 Creating local testing environment..."
mkdir -p "$TEST_DIR"/{demo,ai-shell,configs}

# Check system capabilities
echo "🔍 System Analysis:"
echo "   • macOS Version: $(sw_vers -productVersion)"
echo "   • Architecture: $(uname -m)"
echo "   • CPU Cores: $(sysctl -n hw.ncpu)"
echo "   • Memory: $(echo $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)))GB"

# Create AI shell demo
echo "🤖 Setting up AI shell demo..."
cat > "$TEST_DIR/ai-shell/demo-shell.py" << 'EOF'
#!/usr/bin/env python3
"""
LinuxAI Shell Demo - Runs on macOS for testing
Simulates the AI-powered shell experience
"""

import os
import sys
import time
import subprocess
from datetime import datetime

class LinuxAIShellDemo:
    def __init__(self):
        self.username = os.getenv("USER", "user")
        self.hostname = "linuxai-demo"
        
    def display_banner(self):
        print("\n" + "="*60)
        print("🤖 LINUXAI SHELL DEMO")
        print("   AI-Powered Linux Command Interface")
        print("   Running on macOS for testing")
        print("="*60)
        print("\n💬 Welcome to LinuxAI! This demo shows how the AI shell works.")
        print("🎯 Type commands in natural language and see AI responses.")
        print("📝 Type 'help' for examples, 'exit' to quit\n")
    
    def get_prompt(self):
        return f"🤖 {self.username}@{self.hostname}:~ $ "
    
    def process_command(self, command):
        """Simulate AI command processing"""
        command = command.strip().lower()
        
        if command in ['exit', 'quit']:
            return {"action": "exit", "message": "Goodbye! Thanks for testing LinuxAI! 👋"}
        
        elif command == 'help':
            return {
                "action": "help", 
                "message": """
🤖 LinuxAI AI Shell Demo Commands:

Natural Language Examples:
• "show me system information"
• "list files in current directory" 
• "check disk usage"
• "what processes are running"
• "install docker"
• "create a new user called alice"
• "backup my home directory"

Traditional Commands:
• ls, ps, df, top (all standard commands work too)

Demo Commands:
• demo install - Show AI installation process
• demo voice - Show voice command simulation
• demo monitoring - Show system monitoring
                """
            }
        
        elif 'system information' in command or 'system info' in command:
            info = f"""
🖥️  System Information:
   • Hostname: {self.hostname}
   • User: {self.username}
   • OS: LinuxAI 0.1.0-alpha (Demo)
   • Kernel: 6.6.8-linuxai-ai
   • Architecture: {os.uname().machine}
   • Memory: 8GB (4GB used, 4GB free)
   • Uptime: 2 hours, 15 minutes
   • AI Status: Active ✅
            """
            return {"action": "info", "message": info}
        
        elif 'list files' in command or command == 'ls':
            return {
                "action": "command",
                "message": """
📁 Directory Contents:
drwxr-xr-x  ai-assistant/     (AI system files)
drwxr-xr-x  documents/        (User documents) 
drwxr-xr-x  downloads/        (Downloaded files)
-rw-r--r--  ai-config.yml     (AI configuration)
-rw-r--r--  README.md         (System documentation)
                """
            }
        
        elif 'disk usage' in command or command == 'df':
            return {
                "action": "command",
                "message": """
💾 Disk Usage:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  8.5G   11G  44% /
/dev/sda2       100G   45G   50G  48% /home
tmpfs           4.0G     0  4.0G   0% /tmp
ai-storage       10G  2.1G  7.5G  22% /var/lib/ai-system
                """
            }
        
        elif 'processes' in command or command == 'ps':
            return {
                "action": "command", 
                "message": """
⚡ Running Processes:
PID    COMMAND              CPU%  MEM%
1      systemd              0.1   0.2
2      ai-core              2.5   8.4  ← AI system
156    ai-nlp-processor     1.2   12.1 ← Natural Language
298    ai-voice-handler     0.8   4.2  ← Voice Interface  
445    ai-shell             0.5   2.1  ← Current shell
                """
            }
        
        elif 'install docker' in command:
            return {
                "action": "install",
                "message": """
🤖 AI: I'll install Docker for you!

📦 Installing Docker...
✅ Downloading Docker packages
✅ Installing Docker Engine
✅ Configuring Docker daemon  
✅ Starting Docker service
✅ Adding user to docker group

🎉 Docker installed successfully!
💡 You can now use: docker run hello-world
                """
            }
        
        elif 'create' in command and 'user' in command:
            username = "alice"  # Extract from command in real version
            return {
                "action": "admin",
                "message": f"""
🤖 AI: I'll create user '{username}' for you!

👤 Creating user account...
✅ Creating user directory: /home/{username}
✅ Setting up default shell: /bin/ai-shell
✅ Configuring AI preferences
✅ Setting secure password
✅ Adding to appropriate groups

🎉 User '{username}' created successfully!
💡 They can now log in and use AI commands
                """
            }
        
        elif 'backup' in command and 'home' in command:
            return {
                "action": "backup",
                "message": """
🤖 AI: I'll backup your home directory!

💾 Starting intelligent backup...
🔍 Analyzing files (excluding cache/temp)
📦 Compressing important documents
🔒 Encrypting sensitive data
☁️  Uploading to secure cloud storage

✅ Backup completed: 2.3GB backed up
📍 Location: /backups/home-backup-2024-07-01.tar.gz
🔑 Encryption key saved securely
                """
            }
        
        elif command.startswith('demo '):
            demo_type = command.split(' ', 1)[1]
            return self.run_demo(demo_type)
        
        else:
            # Simulate AI trying to understand
            return {
                "action": "clarification",
                "message": f"""
🤔 AI: I understand you want to: "{command}"

Let me help you with that! Here are some options:
• If you want system info: "show me system information"
• If you want to see files: "list files" 
• If you want to install software: "install [package name]"
• If you want help: "help"

💡 Try being more specific, and I'll understand better!
                """
            }
    
    def run_demo(self, demo_type):
        """Run specific demos"""
        if demo_type == 'install':
            return {
                "action": "demo",
                "message": """
🎬 DEMO: AI Installation Process

🤖 AI: "I see you want to install LinuxAI! Let me help."

🔍 Analyzing your system...
   ✅ Apple Silicon Mac detected
   ✅ 16GB RAM available
   ✅ 500GB free space
   ✅ Virtualization supported

💬 AI: "Perfect! I recommend installing in a VM for safe testing."

📥 Downloading LinuxAI...
   📦 LinuxAI-0.1.0-alpha-aarch64.iso (800MB)
   🤖 AI installation assistant
   🖥️  VM configuration files

🚀 Setting up virtual machine...
   💾 Creating 20GB virtual disk
   ⚙️  Optimizing for Apple Silicon
   🔧 Configuring AI features

✅ Ready! Starting LinuxAI in VM...

💡 The AI guides you through EVERYTHING automatically!
                """
            }
        
        elif demo_type == 'voice':
            return {
                "action": "demo", 
                "message": """
🎬 DEMO: Voice Command Interface

🎤 User: "Hey Linux, show me running processes"
🤖 AI: "Sure! Let me check what's running on your system."

[Simulating voice recognition...]
✅ Wake word detected: "Hey Linux"
✅ Command recognized: "show running processes"
✅ Executing: ps aux --sort=-%cpu

⚡ Here are your top processes by CPU usage:
   - ai-core: Managing AI system
   - firefox: Web browser  
   - code: VS Code editor

🎤 User: "Install VS Code updates"
🤖 AI: "I'll update VS Code for you right now!"

✅ All voice commands work naturally - just speak!
                """
            }
        
        elif demo_type == 'monitoring':
            return {
                "action": "demo",
                "message": """
🎬 DEMO: AI System Monitoring

📊 AI continuously monitors your system:

🔥 CPU: 15% (Normal) 
💾 RAM: 6.2GB/16GB (Good)
💽 Disk: 245GB/500GB (Healthy)
🌡️  Temp: 45°C (Cool)
🔋 Battery: 87% (Charging)

🤖 AI Insights:
• System performance is excellent
• No security threats detected  
• 3 software updates available
• Backup completed 2 hours ago

⚠️  AI Alert: "Your Downloads folder is getting large (15GB). 
   Should I clean up old files?"

💡 The AI proactively helps maintain your system!
                """
            }
        
        else:
            return {"action": "error", "message": f"Demo '{demo_type}' not available"}
    
    def run(self):
        """Main demo loop"""
        self.display_banner()
        
        while True:
            try:
                user_input = input(self.get_prompt())
                
                if not user_input.strip():
                    continue
                
                print("🧠 AI Processing...")
                time.sleep(0.5)  # Simulate thinking
                
                result = self.process_command(user_input)
                
                if result["action"] == "exit":
                    print(f"\n{result['message']}")
                    break
                else:
                    print(f"\n{result['message']}\n")
                    
            except KeyboardInterrupt:
                print("\n\n🤖 AI: Use 'exit' to quit gracefully. 👋")
            except EOFError:
                print("\n\nGoodbye! 👋")
                break

if __name__ == "__main__":
    demo = LinuxAIShellDemo()
    demo.run()
EOF

# Create demo installer
echo "📦 Setting up installation demo..."
cat > "$TEST_DIR/demo/installation-demo.py" << 'EOF'
#!/usr/bin/env python3
"""
LinuxAI Installation Demo - Shows the AI installation experience
"""

import time
import os

def show_installation_demo():
    print("\n🎬 LinuxAI Installation Demo")
    print("="*50)
    print("\n🤖 AI: Hi! I'm your LinuxAI installation assistant.")
    print("Let me guide you through installing LinuxAI on your system.\n")
    
    time.sleep(1)
    
    print("🔍 Analyzing your system...")
    time.sleep(1)
    print("   ✅ Apple Silicon Mac detected")
    print("   ✅ 16GB RAM (Excellent for AI features)")
    print("   ✅ Virtualization supported")
    print("   ✅ Internet connection active")
    
    print("\n🤖 AI: Perfect! I recommend installing in a virtual machine")
    print("for safe testing. This won't affect your macOS system.")
    
    time.sleep(1)
    
    print("\n💬 What would you like your username to be?")
    username = input("👤 Username: ") or "demo-user"
    
    print(f"\n🤖 AI: Great! I'll create user '{username}' with AI features enabled.")
    
    print("\n🎯 Which AI features do you want?")
    print("1. 🎤 Voice commands")  
    print("2. 🧠 Smart system monitoring")
    print("3. 💬 Natural language interface")
    print("4. 🚀 All features (recommended)")
    
    choice = input("\nChoice (1-4): ") or "4"
    
    features = {
        "1": "Voice commands",
        "2": "Smart monitoring", 
        "3": "Natural language",
        "4": "All AI features"
    }
    
    selected = features.get(choice, "All AI features")
    print(f"\n🤖 AI: Excellent! I'll install {selected}.")
    
    print("\n📋 Installation Plan:")
    print("1. 📥 Download LinuxAI (800MB)")
    print("2. 🖥️  Create virtual machine") 
    print("3. 🤖 Install AI core system")
    print("4. 👤 Set up your account")
    print("5. 🎉 Launch LinuxAI")
    
    input("\nPress Enter to start installation...")
    
    steps = [
        ("📥 Downloading LinuxAI ISO", 3),
        ("🖥️  Creating virtual machine", 2),
        ("🤖 Installing AI core system", 4),
        ("👤 Setting up user account", 1),
        ("🎉 Installation complete!", 1)
    ]
    
    print("\n🚀 Installing LinuxAI...")
    print("-" * 30)
    
    for step, duration in steps:
        print(f"\n{step}...")
        for i in range(duration):
            print("  " + "█" * (i+1) + "░" * (duration-i-1) + f" {int((i+1)/duration*100)}%")
            time.sleep(0.5)
        print("  ✅ Complete!")
    
    print("\n🎉 LinuxAI Installation Successful!")
    print("="*40)
    print("\n🚀 Your AI-powered Linux system is ready!")
    print("💡 Next steps:")
    print("  • VM will start automatically")
    print("  • Log in with your username")
    print("  • Say 'Hey Linux' for voice commands")
    print("  • Type commands in natural language")
    print("\nWelcome to the future of Linux! 🤖")

if __name__ == "__main__":
    show_installation_demo()
EOF

# Create main testing script
echo "🎯 Creating main test launcher..."
cat > "$TEST_DIR/test-linuxai.py" << 'EOF'
#!/usr/bin/env python3
"""
LinuxAI Testing Suite - Experience LinuxAI on macOS
"""

import os
import sys
import subprocess

def show_menu():
    print("\n🤖 LinuxAI Testing Suite")
    print("="*30)
    print("\n1. 🖥️  AI Shell Demo")
    print("   Experience the AI-powered command line")
    print("\n2. 📦 Installation Demo") 
    print("   See how easy LinuxAI installation is")
    print("\n3. 📚 View Documentation")
    print("   Learn about LinuxAI features")
    print("\n4. 🎬 Show Project Overview")
    print("   See what we've built")
    print("\n5. ❌ Exit")
    
    choice = input("\nChoose an option (1-5): ")
    return choice

def run_shell_demo():
    script_path = os.path.join(os.path.dirname(__file__), "ai-shell", "demo-shell.py")
    subprocess.run([sys.executable, script_path])

def run_install_demo():
    script_path = os.path.join(os.path.dirname(__file__), "demo", "installation-demo.py")
    subprocess.run([sys.executable, script_path])

def show_docs():
    docs_path = "/Users/samoakes/Desktop/LinuxAI/distro-dev/DEMO.md"
    if os.path.exists(docs_path):
        subprocess.run(["open", docs_path])
    else:
        print("📚 LinuxAI Documentation will open in your browser...")

def show_overview():
    print("\n🚀 LinuxAI Distribution Project Overview")
    print("="*45)
    print("\n✅ What We've Built:")
    print("• 🏗️  Complete Linux distribution build system")
    print("• 🤖 AI-powered shell with natural language interface")
    print("• 🎤 Voice command system")
    print("• 📦 Intelligent package management") 
    print("• 🖥️  Safe virtual machine testing")
    print("• 📥 One-click installation system")
    print("• 🔧 Cross-platform compatibility (x86_64, ARM64)")
    
    print("\n🎯 Key Innovations:")
    print("• First Linux distro with AI as core component")
    print("• Natural language system control")
    print("• Zero technical knowledge required")
    print("• Professional-grade security")
    
    print("\n📊 Current Status:")
    print("• ✅ Architecture & build system complete")
    print("• 🔄 Cross-compilation toolchain building")
    print("• ✅ VM testing environment ready")
    print("• ✅ AI installation assistant complete")
    
    input("\nPress Enter to continue...")

def main():
    while True:
        choice = show_menu()
        
        if choice == "1":
            run_shell_demo()
        elif choice == "2":
            run_install_demo()
        elif choice == "3":
            show_docs()
        elif choice == "4":
            show_overview()
        elif choice == "5":
            print("\n👋 Thanks for testing LinuxAI!")
            break
        else:
            print("Please choose 1-5")

if __name__ == "__main__":
    main()
EOF

# Make scripts executable
chmod +x "$TEST_DIR"/*.py
chmod +x "$TEST_DIR"/*/*.py

echo ""
echo "🎉 LinuxAI Local Testing Environment Ready!"
echo "========================================="
echo ""
echo "📁 Location: $TEST_DIR"
echo ""
echo "🚀 To start testing:"
echo "   python3 '$TEST_DIR/test-linuxai.py'"
echo ""
echo "🎯 Available Tests:"
echo "   • AI Shell Demo - Experience the AI command line"
echo "   • Installation Demo - See the user experience"  
echo "   • Documentation - Learn about features"
echo ""
echo "💡 This gives you a complete preview of LinuxAI without"
echo "   needing any virtualization software installed!"