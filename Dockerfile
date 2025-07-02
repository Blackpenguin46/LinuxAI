FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Create and activate virtual environment, install Python dependencies
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy application files
COPY . .

# Make sure scripts are executable
RUN chmod +x *.py

# Create startup script
RUN echo '#!/bin/bash\n\
echo "🚀 Starting Linux AI System..."\n\
cd /app\n\
source venv/bin/activate\n\
echo "🤖 Starting Ollama service..."\n\
nohup ollama serve > /tmp/ollama.log 2>&1 &\n\
sleep 5\n\
echo "📥 Downloading AI model..."\n\
ollama pull llama3.2:1b\n\
echo ""\n\
echo "✅ Linux AI System Ready!"\n\
echo "========================="\n\
echo "You can now use natural language commands!"\n\
echo ""\n\
python3 main.py\n\
' > /app/start.sh && chmod +x /app/start.sh

EXPOSE 11434

# Default command
CMD ["/app/start.sh"]