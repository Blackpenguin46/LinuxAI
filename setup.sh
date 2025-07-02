#!/bin/bash
# Setup script for LLM-powered Linux AI
# This script sets up the development environment for the Linux AI project

set -e

echo "🚀 Setting up LLM-powered Linux AI development environment..."

# Check if running on supported system
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "⚠️  This setup script is designed for Linux systems."
    echo "   For development on other systems, you may need to adapt the commands."
fi

# Update system packages
echo "📦 Updating system packages..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y python3 python3-pip python3-venv git curl build-essential
elif command -v yum &> /dev/null; then
    sudo yum update -y
    sudo yum install -y python3 python3-pip git curl gcc gcc-c++ make
elif command -v dnf &> /dev/null; then
    sudo dnf update -y
    sudo dnf install -y python3 python3-pip git curl gcc gcc-c++ make
else
    echo "⚠️  Package manager not recognized. Please install Python3, pip, git, and curl manually."
fi

# Install Ollama
echo "🤖 Installing Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    echo "✅ Ollama installed successfully"
else
    echo "✅ Ollama already installed"
fi

# Create Python virtual environment
echo "🐍 Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment and install dependencies
echo "📚 Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Make Python scripts executable
echo "🔧 Making scripts executable..."
chmod +x nlp_frontend.py
chmod +x command_orchestrator.py
chmod +x main.py

# Start Ollama service (if systemd is available)
echo "🔄 Starting Ollama service..."
if command -v systemctl &> /dev/null; then
    sudo systemctl enable ollama
    sudo systemctl start ollama
    sleep 5
else
    echo "⚠️  Systemd not available. You may need to start Ollama manually:"
    echo "   Run: ollama serve"
fi

# Download a lightweight model for testing
echo "📥 Downloading LLM model for testing..."
if command -v ollama &> /dev/null; then
    ollama pull llama2:7b-chat
    echo "✅ Model downloaded successfully"
else
    echo "⚠️  Ollama not in PATH. Please run 'ollama pull llama2:7b-chat' manually"
fi

# Create log directory
echo "📁 Creating log directory..."
mkdir -p /tmp/linux-ai-logs

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Activate the virtual environment: source venv/bin/activate"
echo "2. Test the NLP frontend: python3 nlp_frontend.py"
echo "3. Test the command orchestrator: python3 command_orchestrator.py"
echo "4. Run the main application: python3 main.py"
echo ""
echo "📚 For more information, see the todo.md file for detailed phase instructions."
echo ""
echo "🔧 If you encounter issues:"
echo "   - Check that Ollama is running: ollama list"
echo "   - Verify the model is available: ollama list"
echo "   - Check logs in /tmp/linux-ai-logs/"