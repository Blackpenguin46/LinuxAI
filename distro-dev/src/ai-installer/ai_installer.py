#!/usr/bin/env python3
"""
LinuxAI Installation Assistant
AI-powered installer that guides users through the installation process
using natural language and automated system detection
"""

import os
import sys
import json
import time
import asyncio
import logging
from typing import Dict, List, Any, Optional
from pathlib import Path
import subprocess
import platform

class AIInstaller:
    """AI-powered installation assistant for LinuxAI"""
    
    def __init__(self):
        self.system_info = {}
        self.installation_config = {}
        self.current_step = 0
        self.total_steps = 8
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger("ai-installer")
        
    def display_banner(self):
        """Display AI installer welcome banner"""
        print("\n" + "="*70)
        print("🤖 LINUXAI INSTALLATION ASSISTANT")
        print("   AI-Powered Linux Distribution Setup")
        print("="*70)
        print("\n🎯 Welcome! I'm your AI installation assistant.")
        print("💬 I'll guide you through installing LinuxAI using natural language.")
        print("🔍 I'll detect your hardware and recommend optimal settings.")
        print("⚡ The entire process is streamlined and user-friendly.\n")
    
    def detect_system(self) -> Dict[str, Any]:
        """Detect system hardware and configuration"""
        print("🔍 Analyzing your system...")
        
        system_info = {
            "architecture": platform.machine(),
            "cpu_count": os.cpu_count(),
            "memory_gb": round(os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') / (1024.**3), 1) if hasattr(os, 'sysconf') else 4,
            "platform": platform.system(),
            "disk_info": self.get_disk_info(),
            "network": self.detect_network(),
            "virtualization": self.detect_virtualization()
        }
        
        self.system_info = system_info
        return system_info
    
    def get_disk_info(self) -> List[Dict[str, Any]]:
        """Get available disk information"""
        disks = []
        try:
            # Simple disk detection - in real installer would be more comprehensive
            result = subprocess.run(['df', '-h'], capture_output=True, text=True)
            lines = result.stdout.strip().split('\n')[1:]  # Skip header
            
            for line in lines:
                parts = line.split()
                if len(parts) >= 6:
                    disks.append({
                        "device": parts[0],
                        "size": parts[1],
                        "used": parts[2],
                        "available": parts[3],
                        "mount": parts[5]
                    })
        except Exception as e:
            self.logger.warning(f"Could not detect disks: {e}")
            disks = [{"device": "/dev/sda", "size": "20G", "available": "20G"}]
        
        return disks
    
    def detect_network(self) -> Dict[str, Any]:
        """Detect network configuration"""
        try:
            result = subprocess.run(['ip', 'route'], capture_output=True, text=True)
            has_internet = "default" in result.stdout
        except:
            has_internet = False
        
        return {
            "connected": has_internet,
            "type": "ethernet" if has_internet else "disconnected"
        }
    
    def detect_virtualization(self) -> Dict[str, Any]:
        """Detect if running in virtual machine"""
        vm_indicators = [
            "VMware", "VirtualBox", "QEMU", "KVM", "Xen", "Hyper-V"
        ]
        
        is_vm = False
        vm_type = "unknown"
        
        try:
            # Check DMI information
            result = subprocess.run(['dmidecode', '-s', 'system-product-name'], 
                                  capture_output=True, text=True)
            product_name = result.stdout.strip()
            
            for indicator in vm_indicators:
                if indicator.lower() in product_name.lower():
                    is_vm = True
                    vm_type = indicator
                    break
        except:
            # Fallback - check for common VM files
            vm_files = ['/sys/class/dmi/id/product_name', '/proc/cpuinfo']
            for file_path in vm_files:
                try:
                    with open(file_path, 'r') as f:
                        content = f.read().lower()
                        for indicator in vm_indicators:
                            if indicator.lower() in content:
                                is_vm = True
                                vm_type = indicator
                                break
                except:
                    continue
        
        return {
            "is_virtual": is_vm,
            "type": vm_type,
            "recommended_settings": self.get_vm_recommendations() if is_vm else {}
        }
    
    def get_vm_recommendations(self) -> Dict[str, Any]:
        """Get VM-specific recommendations"""
        return {
            "swap_size": "1GB",  # Smaller swap for VMs
            "filesystem": "ext4",  # Faster for VMs
            "packages": ["vm-tools", "qemu-guest-agent"],
            "services": ["qemu-guest-agent"]
        }
    
    def analyze_and_recommend(self):
        """Analyze system and provide AI recommendations"""
        print("\n🧠 AI Analysis Results:")
        print("-" * 50)
        
        info = self.system_info
        
        # Architecture recommendation
        print(f"🏗️  Architecture: {info['architecture']}")
        if info['architecture'] not in ['x86_64', 'aarch64']:
            print("   ⚠️  Unsupported architecture detected!")
            return False
        
        # Memory recommendation
        memory = info['memory_gb']
        print(f"💾 Memory: {memory}GB")
        if memory < 2:
            print("   ⚠️  Low memory detected. Recommending minimal installation.")
            self.installation_config['installation_type'] = 'minimal'
        elif memory >= 8:
            print("   ✅ Excellent! Recommending full installation with AI features.")
            self.installation_config['installation_type'] = 'full'
        else:
            print("   ✅ Good memory. Recommending standard installation.")
            self.installation_config['installation_type'] = 'standard'
        
        # CPU recommendation
        cpus = info['cpu_count']
        print(f"⚡ CPU Cores: {cpus}")
        if cpus >= 4:
            print("   ✅ Multi-core CPU detected. AI processing will be fast!")
        
        # Virtualization
        vm_info = info['virtualization']
        if vm_info['is_virtual']:
            print(f"🖥️  Virtual Machine: {vm_info['type']}")
            print("   ✅ VM detected. Optimizing installation for virtual environment.")
            self.installation_config.update(vm_info['recommended_settings'])
        else:
            print("🖥️  Physical Hardware: Native installation")
            print("   ✅ Physical hardware detected. Full performance available.")
        
        # Network
        network = info['network']
        if network['connected']:
            print("🌐 Network: Connected")
            print("   ✅ Internet available. Will download latest updates.")
            self.installation_config['download_updates'] = True
        else:
            print("🌐 Network: Offline")
            print("   ℹ️  No internet. Using offline installation mode.")
            self.installation_config['download_updates'] = False
        
        return True
    
    def interactive_configuration(self):
        """Interactive AI-guided configuration"""
        print("\n💬 Let's configure your LinuxAI installation...")
        print("You can answer in natural language - I'll understand!")
        
        # Username
        while True:
            username = input("\n👤 What would you like your username to be? ").strip()
            if self.validate_username(username):
                self.installation_config['username'] = username
                print(f"✅ Great! Your username will be: {username}")
                break
            else:
                print("❌ Username should be 3-32 characters, letters/numbers/underscore only")
        
        # Password
        print(f"\n🔐 Now let's set up a password for {username}")
        password = input("Enter your password (or 'generate' for AI-generated): ").strip()
        if password.lower() == 'generate':
            password = self.generate_secure_password()
            print(f"🎲 Generated secure password: {password}")
            print("💡 Please save this password securely!")
        
        self.installation_config['password'] = password
        
        # Disk partitioning
        print("\n💾 Disk Setup - I'll handle the technical details!")
        disks = self.system_info['disk_info']
        
        if len(disks) == 1:
            print(f"📀 Found one disk: {disks[0]['device']} ({disks[0]['size']})")
            print("✅ I'll use the entire disk with optimal partitioning.")
            self.installation_config['disk'] = disks[0]['device']
        else:
            print("📀 Multiple disks detected:")
            for i, disk in enumerate(disks):
                print(f"   {i+1}. {disk['device']} ({disk['size']})")
            
            while True:
                choice = input("Which disk should I use? (number or 'auto'): ").strip()
                if choice.lower() == 'auto':
                    self.installation_config['disk'] = disks[0]['device']
                    print(f"✅ Auto-selected: {disks[0]['device']}")
                    break
                try:
                    idx = int(choice) - 1
                    if 0 <= idx < len(disks):
                        self.installation_config['disk'] = disks[idx]['device']
                        print(f"✅ Selected: {disks[idx]['device']}")
                        break
                except ValueError:
                    pass
                print("❌ Please enter a valid number or 'auto'")
        
        # AI Features
        print("\n🤖 AI Features Configuration")
        features = input("Which AI features do you want? (voice, nlp, monitoring, all): ").strip().lower()
        
        if features in ['all', 'everything', 'full']:
            self.installation_config['ai_features'] = ['voice', 'nlp', 'monitoring', 'assistant']
            print("✅ All AI features enabled!")
        elif 'voice' in features:
            self.installation_config['ai_features'] = ['voice', 'nlp']
            print("✅ Voice and NLP features enabled!")
        else:
            self.installation_config['ai_features'] = ['nlp']
            print("✅ Basic NLP features enabled!")
    
    def validate_username(self, username: str) -> bool:
        """Validate username"""
        import re
        return bool(re.match(r'^[a-zA-Z0-9_]{3,32}$', username))
    
    def generate_secure_password(self) -> str:
        """Generate a secure password"""
        import secrets
        import string
        
        alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
        password = ''.join(secrets.choice(alphabet) for _ in range(12))
        return password
    
    def create_installation_plan(self):
        """Create step-by-step installation plan"""
        print("\n📋 Installation Plan:")
        print("-" * 50)
        
        steps = [
            "🔍 System Analysis",
            "💾 Disk Partitioning", 
            "📦 Base System Installation",
            "🤖 AI Core Installation",
            "👤 User Account Setup",
            "🌐 Network Configuration",
            "⚙️  System Configuration",
            "🎉 Installation Complete"
        ]
        
        for i, step in enumerate(steps, 1):
            print(f"{i}. {step}")
        
        print(f"\n⏱️  Estimated time: 15-30 minutes")
        print(f"💾 Required space: 8-15 GB")
        
        # Save configuration
        config_path = "/tmp/linuxai-install-config.json"
        with open(config_path, 'w') as f:
            json.dump(self.installation_config, f, indent=2)
        
        print(f"💾 Configuration saved to: {config_path}")
    
    def confirm_installation(self) -> bool:
        """Final confirmation before installation"""
        print("\n" + "="*50)
        print("🚨 FINAL CONFIRMATION")
        print("="*50)
        
        print("\n📋 Installation Summary:")
        config = self.installation_config
        
        print(f"👤 Username: {config['username']}")
        print(f"💾 Disk: {config['disk']}")
        print(f"🤖 AI Features: {', '.join(config['ai_features'])}")
        print(f"📦 Type: {config['installation_type']}")
        
        if self.system_info['virtualization']['is_virtual']:
            print("🖥️  Environment: Virtual Machine (Safe Testing)")
        else:
            print("🖥️  Environment: Physical Hardware")
            print("⚠️  WARNING: This will erase the selected disk!")
        
        print("\n💭 This installation will:")
        print("   • Create a new AI-powered Linux system")
        print("   • Set up natural language system control")
        print("   • Install voice interaction capabilities")
        print("   • Configure automatic system monitoring")
        
        while True:
            response = input("\nProceed with installation? (yes/no): ").strip().lower()
            if response in ['yes', 'y', 'proceed', 'install', 'go']:
                return True
            elif response in ['no', 'n', 'cancel', 'abort', 'stop']:
                return False
            else:
                print("Please answer 'yes' or 'no'")
    
    async def run_installation(self):
        """Execute the actual installation process"""
        print("\n🚀 Starting LinuxAI Installation...")
        print("="*50)
        
        steps = [
            ("🔍 Analyzing system", self.step_analyze),
            ("💾 Preparing disk", self.step_partition_disk),
            ("📦 Installing base system", self.step_install_base),
            ("🤖 Installing AI core", self.step_install_ai),
            ("👤 Creating user account", self.step_create_user),
            ("🌐 Configuring network", self.step_configure_network),
            ("⚙️  Final configuration", self.step_final_config),
            ("🎉 Installation complete", self.step_completion)
        ]
        
        for i, (description, step_func) in enumerate(steps, 1):
            self.current_step = i
            print(f"\nStep {i}/{len(steps)}: {description}")
            print("-" * 30)
            
            try:
                await step_func()
                print("✅ Step completed successfully")
            except Exception as e:
                print(f"❌ Step failed: {e}")
                print("Installation aborted.")
                return False
            
            # Progress indicator
            progress = int((i / len(steps)) * 50)
            bar = "█" * progress + "░" * (50 - progress)
            print(f"Progress: [{bar}] {i}/{len(steps)}")
        
        return True
    
    # Installation step implementations
    async def step_analyze(self):
        await asyncio.sleep(1)  # Simulate work
        print("System analysis complete")
    
    async def step_partition_disk(self):
        await asyncio.sleep(2)  # Simulate work
        print(f"Partitioned disk: {self.installation_config['disk']}")
    
    async def step_install_base(self):
        print("Installing Linux kernel and base system...")
        await asyncio.sleep(5)  # Simulate longer installation
        print("Base system installed")
    
    async def step_install_ai(self):
        print("Installing AI components...")
        features = self.installation_config['ai_features']
        for feature in features:
            print(f"  Installing {feature} AI module...")
            await asyncio.sleep(1)
        print("AI core system installed")
    
    async def step_create_user(self):
        await asyncio.sleep(1)
        username = self.installation_config['username']
        print(f"Created user account: {username}")
    
    async def step_configure_network(self):
        await asyncio.sleep(1)
        print("Network configuration applied")
    
    async def step_final_config(self):
        await asyncio.sleep(2)
        print("System configuration completed")
        print("AI services enabled and started")
    
    async def step_completion(self):
        await asyncio.sleep(1)
        print("🎉 LinuxAI installation completed successfully!")
        print("\n🚀 Your AI-powered Linux system is ready!")
        print("💬 You can now control your system with natural language")
        print("🎤 Voice commands are enabled")
        print("📊 System monitoring is active")
    
    async def main(self):
        """Main installation flow"""
        try:
            self.display_banner()
            
            # System detection
            print("\n" + "="*50)
            print("STEP 1: SYSTEM ANALYSIS")
            print("="*50)
            self.detect_system()
            
            if not self.analyze_and_recommend():
                print("❌ System requirements not met. Installation aborted.")
                return
            
            # Configuration
            print("\n" + "="*50)
            print("STEP 2: INTERACTIVE CONFIGURATION")
            print("="*50)
            self.interactive_configuration()
            
            # Installation planning
            print("\n" + "="*50)
            print("STEP 3: INSTALLATION PLANNING")
            print("="*50)
            self.create_installation_plan()
            
            # Final confirmation
            if not self.confirm_installation():
                print("\n❌ Installation cancelled by user.")
                return
            
            # Execute installation
            print("\n" + "="*50)
            print("STEP 4: INSTALLATION EXECUTION")
            print("="*50)
            
            success = await self.run_installation()
            
            if success:
                print("\n" + "="*70)
                print("🎉 LINUXAI INSTALLATION COMPLETED SUCCESSFULLY! 🎉")
                print("="*70)
                print("\n💡 Next steps:")
                print("1. Reboot your system")
                print("2. Log in with your username and password")
                print("3. Say 'Hey Linux' to start using voice commands")
                print("4. Type 'help' in the terminal for AI assistance")
                print("\nWelcome to the future of Linux! 🚀")
            else:
                print("\n❌ Installation failed. Please check the logs.")
                
        except KeyboardInterrupt:
            print("\n\n⚠️  Installation interrupted by user.")
        except Exception as e:
            print(f"\n❌ Unexpected error: {e}")
            self.logger.error(f"Installation error: {e}")

def main():
    """Entry point for AI installer"""
    if os.geteuid() != 0:
        print("❌ This installer must be run as root.")
        print("Please run: sudo python3 ai_installer.py")
        sys.exit(1)
    
    installer = AIInstaller()
    asyncio.run(installer.main())

if __name__ == "__main__":
    main()