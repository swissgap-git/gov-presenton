#!/bin/bash

echo "🔧 SSH Setup Script for Presenton Server"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update package list
echo "📦 Updating package list..."
apt update

# Install SSH if not installed
echo "🔑 Installing OpenSSH server..."
apt install -y openssh-server

# Start SSH service
echo "🚀 Starting SSH service..."
systemctl start ssh
systemctl enable ssh

# Configure SSH to allow root login with password
echo "⚙️ Configuring SSH..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
echo "🔄 Restarting SSH service..."
systemctl restart ssh

# Check SSH status
echo "📊 SSH Service Status:"
systemctl status ssh --no-pager

# Show SSH configuration
echo ""
echo "🔧 SSH Configuration:"
echo "Port: $(grep '^Port\|^#Port' /etc/ssh/sshd_config | head -1)"
echo "Root Login: $(grep '^PermitRootLogin' /etc/ssh/sshd_config)"
echo "Password Auth: $(grep '^PasswordAuthentication' /etc/ssh/sshd_config)"

# Check firewall
echo ""
echo "🔥 Firewall Status:"
if command -v ufw &> /dev/null; then
    ufw status
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --list-all
else
    echo "No common firewall detected"
fi

# Show IP addresses
echo ""
echo "🌐 Server IP Addresses:"
ip addr show | grep 'inet ' | grep -v '127.0.0.1'

# Test SSH locally
echo ""
echo "🧪 Testing SSH locally..."
ssh -o StrictHostKeyChecking=no root@localhost "echo 'SSH working locally'"

echo ""
echo "✅ SSH Setup Complete!"
echo ""
echo "🔗 Next Steps:"
echo "1. From your local machine, try: ssh root@$(hostname -I | awk '{print $1}')"
echo "2. If still blocked, check firewall settings"
echo "3. Run the deployment script once SSH is working"
