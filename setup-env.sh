#!/bin/bash

# Enable Event Marketer - Docker Setup Script
# This script creates the necessary .env files for configuration

echo "🔧 Setting up Enable Event Marketer environment files..."

# Create backend .env file
cat > backend/.env << 'EOF'
# Backend Environment Variables
SECRET_KEY=your-production-secret-key-change-this-to-something-secure
DATABASE_URL=sqlite:///events.db
CORS_ORIGINS=http://localhost:3000,http://localhost:80,http://localhost
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
FLASK_DEBUG=False
LOG_LEVEL=INFO
EOF

# Create frontend .env file
cat > frontend/.env << 'EOF'
# Frontend Environment Variables
REACT_APP_API_URL=http://localhost:5000
REACT_APP_EMAILJS_SERVICE_ID=your_service_id_here
REACT_APP_EMAILJS_TEMPLATE_ID=your_template_id_here
REACT_APP_EMAILJS_PUBLIC_KEY=your_public_key_here
EOF

echo "✅ Environment files created!"
echo ""
echo "📝 Next steps:"
echo "1. Edit backend/.env with your backend configuration"
echo "2. Edit frontend/.env with your EmailJS credentials:"
echo "   - REACT_APP_EMAILJS_SERVICE_ID"
echo "   - REACT_APP_EMAILJS_TEMPLATE_ID" 
echo "   - REACT_APP_EMAILJS_PUBLIC_KEY"
echo ""
echo "3. Build and run with Docker:"
echo "   docker build -t enable-event-marketer ."
echo "   docker run -p 80:80 -p 5000:5000 -p 3000:3000 enable-event-marketer"
echo ""
echo "   Or use docker-compose:"
echo "   docker-compose up -d"
