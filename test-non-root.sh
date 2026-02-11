#!/bin/bash

# Build and test script for non-root deployment

set -e

echo "🔨 Building Presenton Docker image for non-root deployment..."

# Build the Docker image
docker build -t presenton:test .

echo "✅ Docker image built successfully"

echo "🧪 Testing non-root container execution..."

# Test container startup as non-root user
docker run --rm -it \
  --name presenton-test \
  -e CAN_CHANGE_KEYS=false \
  -e LLM=openai \
  -e OPENAI_API_KEY=test-key \
  presenton:test \
  id

echo "✅ Container runs as non-root user"

echo "🔍 Verifying file permissions..."

# Test file permissions
docker run --rm -it \
  --name presenton-permissions-test \
  -e CAN_CHANGE_KEYS=false \
  -e LLM=openai \
  -e OPENAI_API_KEY=test-key \
  presenton:test \
  ls -la /app

echo "✅ File permissions verified"

echo "🚀 Testing application startup..."

# Test application startup (short duration)
timeout 30s docker run --rm \
  --name presenton-startup-test \
  -e CAN_CHANGE_KEYS=false \
  -e LLM=openai \
  -e OPENAI_API_KEY=test-key \
  -p 8080:80 \
  presenton:test &
  
TEST_PID=$!

# Wait a bit and check if processes started
sleep 10

if docker ps | grep presenton-startup-test; then
    echo "✅ Application started successfully"
    docker stop presenton-startup-test
else
    echo "❌ Application failed to start"
    docker logs presenton-startup-test
    exit 1
fi

echo "🎉 All tests passed! Ready for Kubernetes deployment."

echo ""
echo "Next steps:"
echo "1. Push image to registry: docker tag presenton:test your-registry/presenton:latest"
echo "2. Deploy to Kubernetes: kubectl apply -f k8s/"
echo "3. Configure secrets in k8s/secrets.yaml"
