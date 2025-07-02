#!/bin/bash
# LinuxAI VM Testing Environment Setup
# Creates and manages virtual machines for testing LinuxAI distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VM_DIR="$PROJECT_ROOT/vm-testing"
ISO_DIR="$PROJECT_ROOT/build/iso"

echo "🖥️  Setting up LinuxAI VM testing environment..."

# Create VM directories
mkdir -p "$VM_DIR"/{vms,configs,logs}

# VM Configuration
VM_NAME="linuxai-test"
VM_MEMORY="4096"  # 4GB RAM
VM_DISK_SIZE="20G"
VM_CPUS="2"

# Check for virtualization support
check_virtualization() {
    echo "🔍 Checking virtualization support..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check for virtualization support
        if sysctl -n machdep.cpu.features 2>/dev/null | grep -q VMX; then
            echo "✅ Intel VT-x supported"
        elif sysctl -n machdep.cpu.leaf7_features 2>/dev/null | grep -q VMX; then
            echo "✅ Intel VT-x supported"
        elif [[ $(uname -m) == "arm64" ]]; then
            echo "✅ Apple Silicon - virtualization supported"
        else
            echo "⚠️  Cannot detect virtualization support, but proceeding anyway"
            echo "   (QEMU will work in emulation mode if needed)"
        fi
    else
        # Linux - check for KVM
        if [ -r /proc/cpuinfo ] && grep -q "vmx\|svm" /proc/cpuinfo; then
            echo "✅ Hardware virtualization supported"
        else
            echo "❌ Hardware virtualization not supported"
            exit 1
        fi
    fi
}

# Install QEMU if not present
install_qemu() {
    echo "🔧 Installing QEMU..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v qemu-system-x86_64 &> /dev/null; then
            if command -v brew &> /dev/null; then
                brew install qemu
            else
                echo "❌ Homebrew not found. Please install QEMU manually"
                exit 1
            fi
        fi
    else
        # Linux
        if ! command -v qemu-system-x86_64 &> /dev/null; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y qemu-kvm qemu-utils
            elif command -v yum &> /dev/null; then
                sudo yum install -y qemu-kvm qemu-img
            else
                echo "❌ Please install QEMU manually"
                exit 1
            fi
        fi
    fi
    
    echo "✅ QEMU installed"
}

# Create VM disk
create_vm_disk() {
    local vm_name=$1
    local disk_path="$VM_DIR/vms/$vm_name.qcow2"
    
    echo "💾 Creating VM disk: $disk_path"
    
    if [ ! -f "$disk_path" ]; then
        qemu-img create -f qcow2 "$disk_path" "$VM_DISK_SIZE"
        echo "✅ VM disk created: $VM_DISK_SIZE"
    else
        echo "✅ VM disk already exists"
    fi
}

# Generate VM configuration
generate_vm_config() {
    local vm_name=$1
    local config_path="$VM_DIR/configs/$vm_name.conf"
    
    cat > "$config_path" << EOF
# LinuxAI VM Configuration
VM_NAME="$vm_name"
VM_MEMORY="$VM_MEMORY"
VM_CPUS="$VM_CPUS"
VM_DISK="$VM_DIR/vms/$vm_name.qcow2"
VM_ISO="$ISO_DIR/LinuxAI-0.1.0-alpha-x86_64.iso"
VM_LOG="$VM_DIR/logs/$vm_name.log"

# Network settings
VM_NET="-netdev user,id=net0,hostfwd=tcp::2222-:22 -device e1000,netdev=net0"

# Display settings
VM_DISPLAY="-display cocoa"  # Use SDL on Linux: -display sdl

# Boot settings
VM_BOOT="-boot d"  # Boot from CD-ROM first
EOF

    echo "✅ VM configuration saved: $config_path"
}

# Create VM start script
create_vm_script() {
    local vm_name=$1
    local script_path="$VM_DIR/start-$vm_name.sh"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash
# Start LinuxAI VM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/configs/linuxai-test.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo "🚀 Starting LinuxAI VM..."
echo "💾 Memory: $VM_MEMORY MB"
echo "⚡ CPUs: $VM_CPUS"
echo "💽 Disk: $VM_DISK"
echo "📀 ISO: $VM_ISO"

# Check if ISO exists
if [ ! -f "$VM_ISO" ]; then
    echo "❌ LinuxAI ISO not found: $VM_ISO"
    echo "📦 Please build the ISO first with: make build-iso"
    exit 1
fi

# QEMU command
QEMU_CMD="qemu-system-x86_64 \
    -m $VM_MEMORY \
    -smp $VM_CPUS \
    -hda $VM_DISK \
    -cdrom $VM_ISO \
    $VM_NET \
    $VM_DISPLAY \
    $VM_BOOT \
    -enable-kvm 2>/dev/null || true"

echo "🎮 QEMU Command:"
echo "$QEMU_CMD"
echo ""
echo "💡 VM Controls:"
echo "   - Ctrl+Alt+G: Release mouse"
echo "   - Ctrl+Alt+F: Toggle fullscreen"
echo "   - SSH: ssh user@localhost -p 2222"
echo ""

# Start VM
eval "$QEMU_CMD"
EOF

    chmod +x "$script_path"
    echo "✅ VM start script created: $script_path"
}

# Create VM management script
create_vm_manager() {
    local manager_path="$VM_DIR/vm-manager.sh"
    
    cat > "$manager_path" << 'EOF'
#!/bin/bash
# LinuxAI VM Manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_DIR="$SCRIPT_DIR"

usage() {
    echo "LinuxAI VM Manager"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [vm-name]     - Start VM (default: linuxai-test)"
    echo "  stop [vm-name]      - Stop VM"
    echo "  status              - Show VM status"
    echo "  clean [vm-name]     - Clean VM disk (reset to fresh state)"
    echo "  screenshot [vm-name] - Take VM screenshot"
    echo "  list                - List available VMs"
    echo ""
    echo "Examples:"
    echo "  $0 start            - Start default LinuxAI test VM"
    echo "  $0 clean            - Reset VM to fresh state"
    echo "  $0 screenshot       - Take screenshot of running VM"
}

start_vm() {
    local vm_name=${1:-"linuxai-test"}
    echo "🚀 Starting VM: $vm_name"
    
    if [ -f "$VM_DIR/start-$vm_name.sh" ]; then
        "$VM_DIR/start-$vm_name.sh"
    else
        echo "❌ VM not found: $vm_name"
        exit 1
    fi
}

stop_vm() {
    local vm_name=${1:-"linuxai-test"}
    echo "🛑 Stopping VM: $vm_name"
    
    # Find QEMU process and stop it gracefully
    pkill -f "qemu.*$vm_name" || echo "No running VM found"
}

clean_vm() {
    local vm_name=${1:-"linuxai-test"}
    local disk_path="$VM_DIR/vms/$vm_name.qcow2"
    
    echo "🧹 Cleaning VM disk: $vm_name"
    
    if [ -f "$disk_path" ]; then
        rm "$disk_path"
        echo "✅ VM disk removed"
        
        # Recreate fresh disk
        qemu-img create -f qcow2 "$disk_path" 20G
        echo "✅ Fresh VM disk created"
    else
        echo "❌ VM disk not found: $disk_path"
    fi
}

list_vms() {
    echo "📋 Available VMs:"
    ls -la "$VM_DIR/vms/"*.qcow2 2>/dev/null | awk '{print "  " $9}' | sed 's/.*\///' | sed 's/\.qcow2$//' || echo "  No VMs found"
}

case "${1:-}" in
    start)
        start_vm "$2"
        ;;
    stop)
        stop_vm "$2"
        ;;
    clean)
        clean_vm "$2"
        ;;
    list)
        list_vms
        ;;
    status)
        echo "📊 VM Status:"
        ps aux | grep qemu | grep -v grep || echo "No VMs running"
        ;;
    screenshot)
        echo "📸 Screenshot feature coming soon..."
        ;;
    *)
        usage
        exit 1
        ;;
esac
EOF

    chmod +x "$manager_path"
    echo "✅ VM manager created: $manager_path"
}

# Main setup process
main() {
    check_virtualization
    install_qemu
    create_vm_disk "$VM_NAME"
    generate_vm_config "$VM_NAME"
    create_vm_script "$VM_NAME"
    create_vm_manager
    
    echo ""
    echo "🎉 LinuxAI VM testing environment ready!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Build LinuxAI ISO: make build-iso"
    echo "2. Start VM: $VM_DIR/vm-manager.sh start"
    echo "3. Test installation in safe VM environment"
    echo ""
    echo "🔧 VM Manager commands:"
    echo "  $VM_DIR/vm-manager.sh start   - Start VM"
    echo "  $VM_DIR/vm-manager.sh stop    - Stop VM"
    echo "  $VM_DIR/vm-manager.sh clean   - Reset VM"
    echo "  $VM_DIR/vm-manager.sh list    - List VMs"
}

main "$@"