#!/bin/bash

echo "🐳 Presenton Docker Image Build Script"
echo "====================================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker ist nicht installiert oder nicht im PATH"
    echo ""
    echo "💡 Installation:"
    echo "   1. Führe aus: ./install-docker-and-build.sh"
    echo "   2. Oder installiere Docker manuell:"
    echo "      - macOS: brew install --cask docker"
    echo "      - Linux: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Docker Daemon läuft nicht"
    echo ""
    echo "💡 Lösung:"
    echo "   - macOS: Starte Docker Desktop aus Applications"
    echo "   - Linux: sudo systemctl start docker"
    exit 1
fi

echo "✅ Docker ist verfügbar"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile nicht gefunden"
    echo "💡 Stelle sicher, dass du im Presenton Hauptverzeichnis bist"
    exit 1
fi

# Configuration
IMAGE_NAME=${1:-"presenton"}
IMAGE_TAG=${2:-"latest"}
REGISTRY=${3:-""}

# Full image name
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
else
    FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"
fi

echo ""
echo "🏗️ Build Konfiguration:"
echo "   Image: $FULL_IMAGE_NAME"
echo "   Context: $(pwd)"
echo "   Dockerfile: $(pwd)/Dockerfile"

# Start build
echo ""
echo "📦 Baue Image... (dies kann einige Minuten dauern)"

BUILD_START=$(date +%s)
docker build -t $FULL_IMAGE_NAME .
BUILD_EXIT_CODE=$?
BUILD_END=$(date +%s)

BUILD_TIME=$((BUILD_END - BUILD_START))

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build erfolgreich! (${BUILD_TIME}s)"
    echo ""
    echo "📋 Image Details:"
    docker images | grep $IMAGE_NAME
    
    echo ""
    echo "🚀 Container starten:"
    echo "docker run -it --name presenton -p 5000:80 -v \"\$(pwd)/user_data:/app/user_data\" $FULL_IMAGE_NAME"
    
    echo ""
    echo "🔧 Mit OpenAI Konfiguration:"
    echo "docker run -it --name presenton -p 5000:80 \\"
    echo "  -e LLM=\"openai\" \\"
    echo "  -e OPENAI_API_KEY=\"your-key-here\" \\"
    echo "  -e CAN_CHANGE_KEYS=\"false\" \\"
    echo "  -v \"\$(pwd)/user_data:/app/user_data\" \\"
    echo "  $FULL_IMAGE_NAME"
    
    echo ""
    echo "🔧 Mit Ollama (lokal):"
    echo "docker run -it --name presenton -p 5000:80 \\"
    echo "  -e LLM=\"ollama\" \\"
    echo "  -e OLLAMA_MODEL=\"llama3.2:3b\" \\"
    echo "  -e PEXELS_API_KEY=\"your-pexels-key\" \\"
    echo "  -v \"\$(pwd)/user_data:/app/user_data\" \\"
    echo "  $FULL_IMAGE_NAME"
    
    # Optional: Tag with additional tags
    if [ "$IMAGE_TAG" != "latest" ]; then
        docker tag $FULL_IMAGE_NAME ${IMAGE_NAME}:latest
        echo "✅ Zusätzlich getaggt als: ${IMAGE_NAME}:latest"
    fi
    
else
    echo ""
    echo "❌ Build fehlgeschlagen nach ${BUILD_TIME}s"
    echo ""
    echo "🔍 Debugging:"
    echo "   1. Prüfe Dockerfile auf Syntaxfehler"
    echo "   2. Stelle sicher, dass alle Dateien vorhanden sind"
    echo "   3. Überprüfe Netzwerkverbindung (für Downloads)"
    echo "   4. Versuche: docker build --no-cache -t $FULL_IMAGE_NAME ."
    exit 1
fi

echo ""
echo "🎉 Presenton Image ist bereit!"
