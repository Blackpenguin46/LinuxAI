#!/bin/bash
# LinuxAI Demo Launcher - Run from anywhere

echo "🚀 LinuxAI Demo Launcher"
echo "========================"

DEMO_DIR="/Users/samoakes/Desktop/LinuxAI/distro-dev"

if [ ! -d "$DEMO_DIR" ]; then
    echo "❌ LinuxAI demo directory not found: $DEMO_DIR"
    exit 1
fi

echo "📍 LinuxAI demos available:"
echo "1. 🎬 Complete Demo (recommended)"
echo "2. 🤖 Interactive AI Shell"
echo "3. 📦 Installation Demo"
echo ""

read -p "Choose demo (1-3): " choice

case $choice in
    1)
        echo "🎬 Running complete LinuxAI demo..."
        python3 "$DEMO_DIR/show-linuxai-demo.py"
        ;;
    2)
        echo "🤖 Starting AI shell demo..."
        python3 "$DEMO_DIR/local-testing/ai-shell/demo-shell.py"
        ;;
    3)
        echo "📦 Starting installation demo..."
        python3 "$DEMO_DIR/local-testing/demo/installation-demo.py"
        ;;
    *)
        echo "❌ Invalid choice. Running complete demo..."
        python3 "$DEMO_DIR/show-linuxai-demo.py"
        ;;
esac