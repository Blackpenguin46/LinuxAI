# LLM-powered Linux AI

A proof-of-concept implementation of an AI-enhanced Linux distribution that integrates Large Language Models (LLMs) directly into the operating system, enabling natural language interaction with system commands and functions.

## 🎯 Project Vision

Transform the traditional Linux command-line interface into an intelligent, natural language-driven experience where users can interact with their system using conversational commands instead of memorizing complex shell syntax.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface                       │
├─────────────────────────────────────────────────────────┤
│              Natural Language Processor                │
│                   (nlp_frontend.py)                    │
├─────────────────────────────────────────────────────────┤
│                  LLM Core Services                     │
│                 (Ollama + Local LLM)                   │
├─────────────────────────────────────────────────────────┤
│               Command Orchestrator                     │
│                (command_orchestrator.py)               │
├─────────────────────────────────────────────────────────┤
│              System Interaction Layer                  │
│            (Sandboxed Command Execution)               │
├─────────────────────────────────────────────────────────┤
│                  Linux Base System                     │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Linux-based operating system (Ubuntu LTS recommended)
- Python 3.8+
- 8GB+ RAM (for local LLM inference)
- Internet connection for initial setup

### Installation

1. **Clone and setup the project:**
   ```bash
   cd LinuxAI
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Activate the virtual environment:**
   ```bash
   source venv/bin/activate
   ```

3. **Run the main application:**
   ```bash
   python3 main.py
   ```

### Manual Setup (if setup.sh fails)

1. **Install Ollama:**
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ollama serve
   ```

2. **Download a language model:**
   ```bash
   ollama pull llama2:7b-chat
   ```

3. **Install Python dependencies:**
   ```bash
   pip3 install -r requirements.txt
   ```

## 🎮 Usage Examples

Once running, you can interact with your Linux system using natural language:

```
🤖 LinuxAI> show me my current directory
Generated command: pwd
✅ Command executed successfully
/home/user

🤖 LinuxAI> list all files in this folder
Generated command: ls -la
✅ Command executed successfully
total 48
drwxr-xr-x  8 user user 4096 Jul  1 10:30 .
drwxr-xr-x 15 user user 4096 Jul  1 09:15 ..
-rw-r--r--  1 user user 1234 Jul  1 10:30 main.py
...

🤖 LinuxAI> check how much disk space I have
Generated command: df -h
✅ Command executed successfully
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   12G   35G  26% /
...

🤖 LinuxAI> find all Python files
Generated command: find . -name "*.py"
✅ Command executed successfully
./main.py
./nlp_frontend.py
./command_orchestrator.py
```

## 🔧 Components

### 1. Natural Language Processor (`nlp_frontend.py`)
- Interfaces with Ollama API for LLM communication
- Processes user input and extracts system commands
- Implements conversation history and context management
- Includes basic safety filtering for dangerous commands

### 2. Command Orchestrator (`command_orchestrator.py`)
- Validates and executes LLM-generated commands
- Implements security sandboxing and command whitelisting
- Provides comprehensive logging and audit trails
- Handles command timeouts and error recovery

### 3. Main Application (`main.py`)
- Integrates NLP frontend with command orchestrator
- Provides interactive CLI interface
- Manages user sessions and system status
- Handles special commands and help system

## 🛡️ Security Features

- **Command Validation**: Whitelist of safe commands, blacklist of dangerous operations
- **Sandboxed Execution**: Limited environment variables and restricted permissions  
- **User Confirmation**: Required for potentially risky operations
- **Comprehensive Logging**: All commands and interactions are logged
- **Input Sanitization**: Protection against command injection attacks

## 📊 Development Phases

### ✅ Phase 1: Proof of Concept (Current)
- [x] Natural language shell interface
- [x] Basic LLM integration with Ollama
- [x] Command orchestration and sandboxing
- [x] Safety mechanisms and logging

### 🔄 Phase 2: Enhanced System Interaction (Planned)
- [ ] Comprehensive system API wrapper
- [ ] Multi-step command orchestration
- [ ] System event monitoring
- [ ] Proactive system management

### 🔄 Phase 3: Desktop Integration (Planned)
- [ ] GUI desktop assistant
- [ ] Application plugins and extensions
- [ ] Voice interaction (STT/TTS)
- [ ] Enhanced user experience

### 🔄 Phase 4: Advanced Features (Planned)
- [ ] Dynamic model management
- [ ] Performance optimization
- [ ] Advanced security hardening
- [ ] Distribution packaging

## 🧪 Testing

Test individual components:

```bash
# Test NLP frontend
python3 nlp_frontend.py

# Test command orchestrator
python3 command_orchestrator.py

# Run full system
python3 main.py
```

## 📝 Configuration

The system uses sensible defaults but can be configured:

- **LLM Model**: Change model in `nlp_frontend.py` (default: llama2)
- **Ollama Host**: Modify host URL for remote Ollama instances
- **Security Level**: Adjust command whitelists in `command_orchestrator.py`
- **Logging**: Configure log levels and destinations

## 🤝 Contributing

This is a proof-of-concept project demonstrating the integration of LLMs into Linux systems. Contributions, ideas, and feedback are welcome!

## ⚠️ Important Notes

- **Development Stage**: This is a proof-of-concept, not production-ready
- **Security**: Always review generated commands before execution
- **Resource Usage**: Local LLM inference requires significant computational resources
- **Compatibility**: Tested primarily on Ubuntu LTS systems

## 📜 License

This project is released under the MIT License - see LICENSE file for details.

## 🔗 Related Resources

- [Ollama Documentation](https://ollama.com/docs)
- [Original Inspiration](https://www.instagram.com/reel/DLi5EZCt_OL/)
- [Technical Architecture Document](Technical%20Architecture%20for%20an%20LLM-Powered%20Linux%20Distribution.md)
- [Development Todo List](todo.md)

---

**Built with ❤️ for the future of human-computer interaction**