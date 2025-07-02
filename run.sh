#!/bin/bash

echo "🐳 Building Linux AI Docker image..."
docker build -t linux-ai .

echo ""
echo "🚀 Starting Linux AI System..."
echo "🔗 You can now use natural language commands!"
echo ""

# Run the container interactively
docker run -it --rm \
    --name linux-ai-session \
    -p 11434:11434 \
    linux-ai