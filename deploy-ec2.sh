#!/bin/bash

# Enable Event Marketer - EC2 Deployment Script
# Run this script on your EC2 instance

echo "🚀 Starting Enable Event Marketer deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python 3.11
print_status "Installing Python 3.11..."
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-pip -y

# Install Node.js 18
print_status "Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Nginx
print_status "Installing Nginx..."
sudo apt install nginx -y

# Install PM2
print_status "Installing PM2..."
sudo npm install -g pm2

# Clone repository (update with your actual repository URL)
print_status "Cloning repository..."
if [ ! -d "enable_event_marketer" ]; then
    git clone https://github.com/your-username/enable_event_marketer.git
fi

cd enable_event_marketer

# Deploy Backend
print_status "Deploying backend..."
cd backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export SECRET_KEY="your-production-secret-key-$(date +%s)"
export DATABASE_URL="sqlite:///events.db"
export CORS_ORIGINS="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
export FLASK_HOST="0.0.0.0"
export FLASK_PORT="5000"
export FLASK_DEBUG="False"

# Start backend with PM2
pm2 start app.py --name "enable-backend" --interpreter python3.11

# Deploy Frontend
print_status "Deploying frontend..."
cd ../frontend

# Install dependencies
npm install

# Build for production
npm run build

# Install serve and start frontend
sudo npm install -g serve
pm2 start "serve -s build -l 3000" --name "enable-frontend"

# Save PM2 configuration
pm2 save
pm2 startup

# Configure Nginx
print_status "Configuring Nginx..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

sudo tee /etc/nginx/sites-available/enable-app > /dev/null <<EOF
server {
    listen 80;
    server_name $PUBLIC_IP;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/enable-app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# Configure firewall
print_status "Configuring firewall..."
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

print_status "🎉 Deployment completed!"
print_status "Your application is now running at: http://$PUBLIC_IP"
print_status "Backend API: http://$PUBLIC_IP/api/"
print_status "Health check: http://$PUBLIC_IP/api/health"

print_warning "Don't forget to:"
print_warning "1. Update frontend/src/config/api.js with your EC2 IP"
print_warning "2. Set up SSL certificate with Certbot"
print_warning "3. Configure your domain to point to this IP"
print_warning "4. Set up regular backups"

echo ""
print_status "Useful commands:"
print_status "pm2 list          # List processes"
print_status "pm2 logs          # View logs"
print_status "pm2 restart all   # Restart all services"
print_status "sudo systemctl status nginx  # Check Nginx status"
