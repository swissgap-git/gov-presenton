#!/bin/bash

# Kubernetes Build & Push Script für Presenton
IMAGE_NAME="presenton"
VERSION=${1:-latest}
REGISTRY=${2:-"docker.io/your-username"}  # Ändere zu deinem Registry

echo "🐳 Building Docker Image for Kubernetes..."
echo "Image: $REGISTRY/$IMAGE_NAME:$VERSION"

# Dockerfile prüfen
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile nicht gefunden!"
    exit 1
fi

# Image bauen
docker build -t $REGISTRY/$IMAGE_NAME:$VERSION .
docker tag $REGISTRY/$IMAGE_NAME:$VERSION $REGISTRY/$IMAGE_NAME:latest

# Image infos anzeigen
echo ""
echo "📋 Image Informationen:"
docker images | grep $IMAGE_NAME

# Push prompt
echo ""
read -p "🚀 Image pushen zu $REGISTRY? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔑 Login bei Registry..."
    docker login $REGISTRY
    
    echo "📤 Pushing Image..."
    docker push $REGISTRY/$IMAGE_NAME:$VERSION
    docker push $REGISTRY/$IMAGE_NAME:latest
    
    echo "✅ Image erfolgreich gepusht!"
    echo ""
    echo "📝 Kubernetes Deployment Command:"
    echo "sed -i 's|IMAGE_PLACEHOLDER|$REGISTRY/$IMAGE_NAME:$VERSION|' k8s-deployment.yaml"
    echo "kubectl apply -f k8s-deployment.yaml"
else
    echo "❌ Push abgebrochen"
fi
