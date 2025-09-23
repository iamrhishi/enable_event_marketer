# Enable Event Marketer - Complete Docker Setup
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nginx \
    supervisor \
    software-properties-common \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-venv python3.11-pip python3.11-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install PM2 globally
RUN npm install -g pm2 serve

# Create application directory
WORKDIR /app

# Clone the repository (update with your actual repository URL)
RUN git clone https://github.com/your-username/enable_event_marketer.git .

# Set up Backend
WORKDIR /app/backend

# Create virtual environment
RUN python3.11 -m venv venv

# Activate virtual environment and install dependencies
RUN /bin/bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

# Create .env file for backend
RUN echo 'SECRET_KEY=your-production-secret-key-change-this' > .env && \
    echo 'DATABASE_URL=sqlite:///events.db' >> .env && \
    echo 'CORS_ORIGINS=http://localhost:3000,http://localhost:80,http://localhost' >> .env && \
    echo 'FLASK_HOST=0.0.0.0' >> .env && \
    echo 'FLASK_PORT=5000' >> .env && \
    echo 'FLASK_DEBUG=False' >> .env && \
    echo 'LOG_LEVEL=INFO' >> .env

# Set up Frontend
WORKDIR /app/frontend

# Install dependencies
RUN npm install

# Create .env file for frontend
RUN echo 'REACT_APP_API_URL=http://localhost:5000' > .env && \
    echo 'REACT_APP_EMAILJS_SERVICE_ID=your_service_id_here' >> .env && \
    echo 'REACT_APP_EMAILJS_TEMPLATE_ID=your_template_id_here' >> .env && \
    echo 'REACT_APP_EMAILJS_PUBLIC_KEY=your_public_key_here' >> .env

# Build frontend
RUN npm run build

# Create Nginx configuration
RUN cat > /etc/nginx/sites-available/enable-app << 'EOF'
server {
    listen 80;
    server_name localhost;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable Nginx site
RUN ln -sf /etc/nginx/sites-available/enable-app /etc/nginx/sites-enabled/ && \
    rm -f /etc/nginx/sites-enabled/default

# Create PM2 ecosystem file
RUN cat > /app/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'enable-backend',
      script: 'app.py',
      cwd: '/app/backend',
      interpreter: '/app/backend/venv/bin/python3.11',
      env: {
        SECRET_KEY: 'your-production-secret-key-change-this',
        DATABASE_URL: 'sqlite:///events.db',
        CORS_ORIGINS: 'http://localhost:3000,http://localhost:80,http://localhost',
        FLASK_HOST: '0.0.0.0',
        FLASK_PORT: '5000',
        FLASK_DEBUG: 'False',
        LOG_LEVEL: 'INFO'
      }
    },
    {
      name: 'enable-frontend',
      script: 'serve',
      args: '-s build -l 3000',
      cwd: '/app/frontend',
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
};
EOF

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Enable Event Marketer..."

# Start services with PM2
cd /app
pm2 start ecosystem.config.js

# Start Nginx
service nginx start

# Keep container running
pm2 logs
EOF

RUN chmod +x /app/start.sh

# Expose ports
EXPOSE 80 5000 3000

# Set working directory
WORKDIR /app

# Start the application
CMD ["/app/start.sh"]
