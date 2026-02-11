#!/bin/bash

echo "🐳 Docker Installation & Presenton Image Build Script (Ubuntu)"
echo "============================================================="

# Check if running as root for installation
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  Running as root detected. This script should be run as a regular user with sudo privileges."
    echo "   The script will use sudo for installation commands where needed."
    echo ""
fi

# Check if running on Ubuntu/Debian
if ! grep -q "Ubuntu\|Debian" /etc/os-release 2>/dev/null; then
    echo "❌ Dieses Skript ist nur für Ubuntu/Debian geeignet"
    echo "   Erkanntes System: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
echo "🔧 Architektur: $ARCH"

# Update package list
echo "📦 Aktualisiere Paketliste..."
sudo apt update

# Install prerequisites
echo "📦 Installiere Voraussetzungen..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
echo "🔑 Füge Docker GPG Schlüssel hinzu..."
if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "✅ Docker GPG Schlüssel hinzugefügt"
else
    echo "✅ Docker GPG Schlüssel bereits vorhanden"
fi

# Set up the stable repository
echo "📋 Richte Docker Repository ein..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt update

# Install Docker Engine
if ! command -v docker &> /dev/null; then
    echo "🐳 Installiere Docker Engine..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker service
    echo "🚀 Starte Docker Service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    echo "👤 Füge Benutzer '$USER' zur docker Gruppe hinzu..."
    sudo usermod -aG docker $USER
    
    echo ""
    echo "⚠️  WICHTIG: Benutzer wurde zur docker Gruppe hinzugefügt!"
    echo "   1. Logge dich aus und wieder ein ODER führe aus: newgrp docker"
    echo "   2. Drücke ENTER um fortzufahren..."
    read
    
else
    echo "✅ Docker bereits installiert"
fi

# Verify Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker läuft nicht. Starte Docker Service..."
    sudo systemctl start docker
    sleep 3
    
    if ! docker info &> /dev/null; then
        echo "❌ Docker konnte nicht gestartet werden."
        echo "   Mögliche Lösungen:"
        echo "   1. Führe aus: sudo systemctl start docker"
        echo "   2. Überprüfe mit: sudo systemctl status docker"
        echo "   3. Logge dich aus und wieder ein (für docker Gruppenmitgliedschaft)"
        exit 1
    else
        echo "✅ Docker Service erfolgreich gestartet!"
    fi
else
    echo "✅ Docker läuft bereits"
fi

echo ""
echo "🏗️ Baue Presenton Docker Image..."

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile nicht gefunden im aktuellen Verzeichnis"
    exit 1
fi

# Build the image
IMAGE_NAME="presenton"
IMAGE_TAG="latest"

echo "📦 Build: $IMAGE_NAME:$IMAGE_TAG"
docker build -t $IMAGE_NAME:$IMAGE_TAG .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker Image erfolgreich gebaut!"
    echo ""
    echo "📋 Image Informationen:"
    docker images | grep $IMAGE_NAME
    
    echo ""
    echo "🚀 Test-Container starten:"
    echo "docker run -it --name presenton-test -p 5000:80 -v \"\$(pwd)/user_data:/app/user_data\" $IMAGE_NAME:$IMAGE_TAG"
    
    echo ""
    echo "🔧 Mit Environment Variablen:"
    echo "docker run -it --name presenton -p 5000:80 \\"
    echo "  -e LLM=\"openai\" \\"
    echo "  -e OPENAI_API_KEY=\"your-key-here\" \\"
    echo "  -e CAN_CHANGE_KEYS=\"false\" \\"
    echo "  -v \"\$(pwd)/user_data:/app/user_data\" \\"
    echo "  $IMAGE_NAME:$IMAGE_TAG"
    
else
    echo "❌ Docker Build fehlgeschlagen"
    exit 1
fi

echo ""
echo "🎉 Fertig! Das Presenton Image ist bereit für den Einsatz."
