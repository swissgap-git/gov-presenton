#!/bin/bash

# Server Deployment Script for Presenton
# Usage: ./deploy-server.sh [server-ip]

SERVER_IP=${1:-192.168.200.85}
REMOTE_DIR="/opt/presenton"
PROJECT_NAME="presenton"

echo "🚀 Deploying Presenton to server $SERVER_IP..."

# Check if SSH key exists or create one
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "🔑 Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Copy SSH key to server (one-time setup)
echo "📤 Copying SSH key to server..."
ssh-copy-id root@$SERVER_IP

# Create remote directory
echo "📁 Creating remote directory..."
ssh root@$SERVER_IP "mkdir -p $REMOTE_DIR && cd $REMOTE_DIR"

# Copy project files to server
echo "📦 Copying project files..."
scp -r /Users/gap/Downloads/presenton-main/* root@$SERVER_IP:$REMOTE_DIR/

# Install Docker on server if not installed
echo "🐳 Checking Docker installation..."
ssh root@$SERVER_IP "
if ! command -v docker &> /dev/null; then
    echo 'Installing Docker...'
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
else
    echo 'Docker already installed'
fi
"

# Install Docker Compose if not installed
echo "🔧 Checking Docker Compose installation..."
ssh root@$SERVER_IP "
if ! command -v docker-compose &> /dev/null; then
    echo 'Installing Docker Compose...'
    curl -L 'https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64' -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo 'Docker Compose already installed'
fi
"

# Build Docker image on server
echo "🏗️ Building Docker image on server..."
ssh root@$SERVER_IP "cd $REMOTE_DIR && docker build -t $PROJECT_NAME:latest ."

# Create environment file
echo "⚙️ Creating environment file..."
ssh root@$SERVER_IP "cd $REMOTE_DIR && cat > .env << 'EOF'
# Production Configuration
CAN_CHANGE_KEYS=false
NODE_ENV=production
APP_DATA_DIRECTORY=/app/user_data
TEMP_DIRECTORY=/tmp/presenton

# AI Provider Configuration
LLM=openai
OPENAI_API_KEY=your-openai-api-key-here
GOOGLE_API_KEY=your-google-api-key-here
OLLAMA_MODEL=llama3.2:3b
PEXELS_API_KEY=your-pexels-api-key-here

# EIAM Configuration (if needed)
SESSION_SECRET_KEY=your-32-character-secret-key-minimum
EIAM_CLIENT_ID=your-eiam-client-id-here
EIAM_CLIENT_SECRET=your-eiam-client-secret-here
EIAM_TENANT_ID=your-eiam-tenant-id-here
EIAM_REDIRECT_URI=https://your-domain.ch/auth/callback
EOF"

# Run the application
echo "🚀 Starting Presenton application..."
ssh root@$SERVER_IP "cd $REMOTE_DIR && docker-compose up -d"

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 30

# Check if application is running
echo "🔍 Checking application status..."
ssh root@$SERVER_IP "docker ps | grep $PROJECT_NAME"

# Get server IP and display access information
echo ""
echo "✅ Deployment completed!"
echo ""
echo "📋 Access Information:"
echo "🌐 Application URL: http://$SERVER_IP:5000"
echo "🔧 Admin Panel: http://$SERVER_IP:5000/dashboard"
echo "📊 API Documentation: http://$SERVER_IP:5000/docs"
echo ""
echo "🔑 Next Steps:"
echo "1. Update API keys in .env file on server"
echo "2. Configure domain name and SSL certificate"
echo "3. Set up firewall rules for port 5000"
echo "4. Configure backup for user data"
echo ""
echo "🖥️ Management Commands:"
echo "View logs: ssh root@$SERVER_IP 'cd $REMOTE_DIR && docker-compose logs -f'"
echo "Stop app: ssh root@$SERVER_IP 'cd $REMOTE_DIR && docker-compose down'"
echo "Restart app: ssh root@$SERVER_IP 'cd $REMOTE_DIR && docker-compose restart'"
echo "Update app: ssh root@$SERVER_IP 'cd $REMOTE_DIR && git pull && docker-compose up -d --build'"
