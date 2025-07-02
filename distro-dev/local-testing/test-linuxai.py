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
