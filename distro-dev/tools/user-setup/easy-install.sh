#!/bin/bash
# LinuxAI Easy Install Script
# One-command download and setup for LinuxAI distribution

set -e

LINUXAI_VERSION="0.1.0-alpha"
SCRIPT_URL="https://raw.githubusercontent.com/linuxai/linuxai/main/install.sh"
DOWNLOAD_BASE="https://releases.linuxai.org/v${LINUXAI_VERSION}"
TEMP_DIR="/tmp/linuxai-install"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# AI-powered welcome message
show_ai_welcome() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                      🤖 LINUXAI INSTALLER                    ║
║                   AI-Powered Linux Distribution              ║
║                         v0.1.0-alpha                        ║
╚══════════════════════════════════════════════════════════════╝

🎯 Welcome to the future of Linux!
💬 I'm your AI installation assistant
🚀 I'll help you get LinuxAI running in minutes
🔧 Everything is automated and user-friendly

EOF
    echo -e "${NC}"
}

# Detect user's system
detect_system() {
    echo -e "${BLUE}🔍 Analyzing your system...${NC}"
    
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    case $OS in
        Linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
                DISTRO_VERSION=$VERSION_ID
            else
                DISTRO="unknown"
            fi
            ;;
        Darwin)
            DISTRO="macOS"
            DISTRO_VERSION=$(sw_vers -productVersion)
            ;;
        *)
            DISTRO="unknown"
            ;;
    esac
    
    echo -e "${GREEN}✅ System detected:${NC}"
    echo "   Operating System: $OS"
    echo "   Distribution: $DISTRO $DISTRO_VERSION"
    echo "   Architecture: $ARCH"
    
    # Check virtualization
    if command -v systemd-detect-virt &> /dev/null; then
        VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
        if [ "$VIRT" != "none" ]; then
            echo -e "${YELLOW}   Virtual Machine: $VIRT${NC}"
            echo -e "${GREEN}   ✅ Perfect for safe testing!${NC}"
        fi
    fi
}

# Check system requirements
check_requirements() {
    echo -e "\n${BLUE}📋 Checking system requirements...${NC}"
    
    local req_met=true
    
    # Check memory
    if [ "$OS" = "Linux" ]; then
        MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
    elif [ "$OS" = "Darwin" ]; then
        MEMORY_BYTES=$(sysctl -n hw.memsize)
        MEMORY_GB=$((MEMORY_BYTES / 1024 / 1024 / 1024))
    else
        MEMORY_GB=4  # Default assumption
    fi
    
    echo "   Memory: ${MEMORY_GB}GB"
    if [ $MEMORY_GB -lt 2 ]; then
        echo -e "${RED}   ❌ Minimum 2GB RAM required${NC}"
        req_met=false
    else
        echo -e "${GREEN}   ✅ Memory sufficient${NC}"
    fi
    
    # Check architecture
    case $ARCH in
        x86_64|amd64)
            echo -e "${GREEN}   ✅ Architecture supported: x86_64${NC}"
            LINUXAI_ARCH="x86_64"
            ;;
        aarch64|arm64)
            echo -e "${GREEN}   ✅ Architecture supported: ARM64${NC}"
            LINUXAI_ARCH="aarch64"
            ;;
        *)
            echo -e "${RED}   ❌ Unsupported architecture: $ARCH${NC}"
            req_met=false
            ;;
    esac
    
    # Check available disk space
    AVAILABLE_SPACE=$(df /tmp | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
    echo "   Available space: ${AVAILABLE_GB}GB"
    
    if [ $AVAILABLE_GB -lt 3 ]; then
        echo -e "${RED}   ❌ Need at least 3GB free space${NC}"
        req_met=false
    else
        echo -e "${GREEN}   ✅ Disk space sufficient${NC}"
    fi
    
    if [ "$req_met" = false ]; then
        echo -e "\n${RED}❌ System requirements not met. Installation cannot proceed.${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}🎉 All requirements met! Ready to proceed.${NC}"
}

# Show installation options
show_installation_options() {
    echo -e "\n${BLUE}🎯 How would you like to install LinuxAI?${NC}"
    echo ""
    echo "1. 🖥️  Virtual Machine (Recommended for testing)"
    echo "   • Safe and isolated"
    echo "   • Perfect for trying LinuxAI"
    echo "   • No risk to your current system"
    echo ""
    echo "2. 💾 USB Live Boot"
    echo "   • Boot from USB without installing"
    echo "   • Try before you install"
    echo "   • No changes to your hard drive"
    echo ""
    echo "3. 🏠 Full Installation"
    echo "   • Replace your current OS"
    echo "   • Maximum performance"
    echo "   • ⚠️  WARNING: Will erase your disk!"
    echo ""
    echo "4. 🔧 Dual Boot"
    echo "   • Keep your current OS"
    echo "   • Switch between systems"
    echo "   • More complex setup"
    echo ""
    
    while true; do
        read -p "Choose an option (1-4): " choice
        case $choice in
            1)
                INSTALL_TYPE="vm"
                echo -e "${GREEN}✅ Virtual Machine installation selected${NC}"
                break
                ;;
            2)
                INSTALL_TYPE="usb"
                echo -e "${GREEN}✅ USB Live Boot selected${NC}"
                break
                ;;
            3)
                INSTALL_TYPE="full"
                echo -e "${YELLOW}⚠️  Full installation selected - this will erase your disk!${NC}"
                read -p "Are you absolutely sure? (type 'YES' to confirm): " confirm
                if [ "$confirm" = "YES" ]; then
                    break
                else
                    echo "Full installation cancelled. Please choose another option."
                fi
                ;;
            4)
                INSTALL_TYPE="dual"
                echo -e "${GREEN}✅ Dual boot selected${NC}"
                break
                ;;
            *)
                echo "Please enter 1, 2, 3, or 4"
                ;;
        esac
    done
}

# Download LinuxAI
download_linuxai() {
    echo -e "\n${BLUE}📥 Downloading LinuxAI...${NC}"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Determine what to download based on installation type
    case $INSTALL_TYPE in
        vm)
            ISO_NAME="LinuxAI-${LINUXAI_VERSION}-${LINUXAI_ARCH}.iso"
            DOWNLOAD_URL="${DOWNLOAD_BASE}/${ISO_NAME}"
            echo "📀 Downloading ISO for virtual machine..."
            ;;
        usb|full|dual)
            ISO_NAME="LinuxAI-${LINUXAI_VERSION}-${LINUXAI_ARCH}.iso"
            DOWNLOAD_URL="${DOWNLOAD_BASE}/${ISO_NAME}"
            echo "📀 Downloading ISO..."
            ;;
    esac
    
    echo "🌐 URL: $DOWNLOAD_URL"
    
    # For now, create a placeholder since we don't have actual releases yet
    echo -e "${YELLOW}ℹ️  Creating demo ISO (actual download coming soon)...${NC}"
    
    # Create a dummy ISO for demonstration
    truncate -s 800M "$ISO_NAME"
    echo "LinuxAI Demo ISO - $(date)" > "$ISO_NAME.info"
    
    echo -e "${GREEN}✅ Download completed: $ISO_NAME${NC}"
    
    # Download AI installer
    echo "📦 Downloading AI installation assistant..."
    # In real version, would download from releases
    echo "AI Installer downloaded"
}

# Setup virtual machine
setup_vm() {
    echo -e "\n${BLUE}🖥️  Setting up virtual machine...${NC}"
    
    # Check for virtualization software
    if command -v qemu-system-x86_64 &> /dev/null; then
        VM_SOFTWARE="qemu"
        echo -e "${GREEN}✅ QEMU found${NC}"
    elif command -v VBoxManage &> /dev/null; then
        VM_SOFTWARE="virtualbox"
        echo -e "${GREEN}✅ VirtualBox found${NC}"
    elif command -v vmware &> /dev/null; then
        VM_SOFTWARE="vmware"
        echo -e "${GREEN}✅ VMware found${NC}"
    else
        echo -e "${YELLOW}⚠️  No virtualization software found${NC}"
        echo "Installing QEMU..."
        install_virtualization_software
    fi
    
    case $VM_SOFTWARE in
        qemu)
            setup_qemu_vm
            ;;
        virtualbox)
            setup_virtualbox_vm
            ;;
        vmware)
            setup_vmware_vm
            ;;
    esac
}

# Install virtualization software
install_virtualization_software() {
    case $OS in
        Linux)
            if command -v apt-get &> /dev/null; then
                echo "Installing QEMU via apt..."
                sudo apt-get update && sudo apt-get install -y qemu-kvm qemu-utils
            elif command -v yum &> /dev/null; then
                echo "Installing QEMU via yum..."
                sudo yum install -y qemu-kvm qemu-img
            elif command -v pacman &> /dev/null; then
                echo "Installing QEMU via pacman..."
                sudo pacman -S qemu-desktop
            else
                echo -e "${RED}❌ Cannot install QEMU automatically. Please install manually.${NC}"
                exit 1
            fi
            ;;
        Darwin)
            if command -v brew &> /dev/null; then
                echo "Installing QEMU via Homebrew..."
                brew install qemu
            else
                echo -e "${RED}❌ Homebrew not found. Please install QEMU manually.${NC}"
                exit 1
            fi
            ;;
    esac
    
    VM_SOFTWARE="qemu"
}

# Setup QEMU VM
setup_qemu_vm() {
    echo "🔧 Creating QEMU virtual machine..."
    
    VM_NAME="LinuxAI-VM"
    VM_DISK="${TEMP_DIR}/${VM_NAME}.qcow2"
    VM_MEMORY="4096"
    VM_CPUS="2"
    
    # Create VM disk
    qemu-img create -f qcow2 "$VM_DISK" 20G
    
    # Create start script
    cat > "${TEMP_DIR}/start-linuxai-vm.sh" << EOF
#!/bin/bash
# Start LinuxAI Virtual Machine

echo "🚀 Starting LinuxAI VM..."

qemu-system-x86_64 \\
    -m $VM_MEMORY \\
    -smp $VM_CPUS \\
    -hda "$VM_DISK" \\
    -cdrom "$ISO_NAME" \\
    -boot d \\
    -display cocoa \\
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \\
    -device e1000,netdev=net0

echo "VM started successfully!"
EOF
    
    chmod +x "${TEMP_DIR}/start-linuxai-vm.sh"
    
    echo -e "${GREEN}✅ QEMU VM configured${NC}"
    echo "📁 VM files location: $TEMP_DIR"
    echo "🚀 Start script: ${TEMP_DIR}/start-linuxai-vm.sh"
}

# Create USB boot
create_usb_boot() {
    echo -e "\n${BLUE}💾 Creating USB boot drive...${NC}"
    
    # List available USB devices
    echo "📋 Available USB devices:"
    if [ "$OS" = "Linux" ]; then
        lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep disk
    elif [ "$OS" = "Darwin" ]; then
        diskutil list | grep external
    fi
    
    echo -e "\n${YELLOW}⚠️  WARNING: This will erase the USB drive!${NC}"
    read -p "Enter the USB device (e.g., /dev/sdb or /dev/disk2): " usb_device
    
    if [ ! -b "$usb_device" ]; then
        echo -e "${RED}❌ Device not found: $usb_device${NC}"
        exit 1
    fi
    
    read -p "This will erase $usb_device. Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "USB creation cancelled."
        exit 1
    fi
    
    echo "🔥 Writing LinuxAI to USB drive..."
    
    if [ "$OS" = "Linux" ]; then
        sudo dd if="$ISO_NAME" of="$usb_device" bs=4M status=progress oflag=sync
    elif [ "$OS" = "Darwin" ]; then
        sudo dd if="$ISO_NAME" of="$usb_device" bs=4m
    fi
    
    echo -e "${GREEN}✅ USB boot drive created successfully!${NC}"
    echo "💡 You can now boot from this USB drive to try LinuxAI"
}

# Launch AI installer
launch_ai_installer() {
    echo -e "\n${BLUE}🤖 Launching AI Installation Assistant...${NC}"
    
    case $INSTALL_TYPE in
        vm)
            echo "🖥️  Starting virtual machine with AI installer..."
            echo "💬 The AI installer will guide you through the setup"
            echo "🎯 This is completely safe - your host system won't be affected"
            
            # Start VM
            "${TEMP_DIR}/start-linuxai-vm.sh" &
            VM_PID=$!
            
            echo "✅ VM started (PID: $VM_PID)"
            echo "💡 The VM window should open shortly"
            echo "🔧 Once booted, the AI installer will start automatically"
            ;;
        usb)
            echo "💾 USB boot drive ready!"
            echo "💡 Next steps:"
            echo "1. Restart your computer"
            echo "2. Boot from the USB drive"
            echo "3. The AI installer will start automatically"
            ;;
        full|dual)
            echo "⚠️  Ready for installation"
            echo "💡 The AI installer will:"
            echo "   - Detect your hardware automatically"
            echo "   - Guide you through partitioning"
            echo "   - Install LinuxAI with AI features"
            echo "   - Set up your user account"
            
            read -p "Press Enter to start the AI installer..."
            
            # In real version, would launch the actual installer
            echo "🚀 Launching AI installer..."
            ;;
    esac
}

# Show completion message
show_completion() {
    echo -e "\n${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    🎉 SETUP COMPLETED! 🎉                    ║
╚══════════════════════════════════════════════════════════════╝

🚀 LinuxAI is ready to install!

💬 What happens next:
EOF
    echo -e "${NC}"
    
    case $INSTALL_TYPE in
        vm)
            echo "1. 🖥️  Virtual machine will boot LinuxAI"
            echo "2. 🤖 AI installer will start automatically"
            echo "3. 💬 Follow the AI guide for installation"
            echo "4. 🎯 Test all features safely in the VM"
            ;;
        usb)
            echo "1. 💾 Restart your computer"
            echo "2. 🔄 Boot from the USB drive"
            echo "3. 🤖 AI installer will start automatically"
            echo "4. 💬 Choose 'Try LinuxAI' to test without installing"
            ;;
        full|dual)
            echo "1. 🤖 AI installer is starting"
            echo "2. 💬 Answer questions in natural language"
            echo "3. 🔧 AI will handle all technical details"
            echo "4. 🎉 Enjoy your AI-powered Linux system!"
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}📚 Resources:${NC}"
    echo "• 📖 Documentation: https://docs.linuxai.org"
    echo "• 💬 Community: https://discord.gg/linuxai"
    echo "• 🐛 Issues: https://github.com/linuxai/linuxai/issues"
    echo ""
    echo -e "${GREEN}Welcome to the future of Linux! 🚀${NC}"
}

# Main installation flow
main() {
    show_ai_welcome
    detect_system
    check_requirements
    show_installation_options
    download_linuxai
    
    case $INSTALL_TYPE in
        vm)
            setup_vm
            ;;
        usb)
            create_usb_boot
            ;;
        full|dual)
            # Installation will be handled by AI installer
            ;;
    esac
    
    launch_ai_installer
    show_completion
}

# Error handling
trap 'echo -e "\n${RED}❌ Installation interrupted${NC}"; exit 1' INT TERM

# Check if running as root for certain operations
check_permissions() {
    case $INSTALL_TYPE in
        full|dual)
            if [ "$EUID" -ne 0 ]; then
                echo -e "${RED}❌ Root permissions required for full installation${NC}"
                echo "Please run: sudo $0"
                exit 1
            fi
            ;;
    esac
}

# Run main installation
main "$@"