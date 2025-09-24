#!/bin/bash

# Start script for Event Marketer Application
echo "🚀 Starting Event Marketer Application..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python version
check_python_version() {
    if command_exists python3.11; then
        PYTHON_CMD="python3.11"
    elif command_exists python3; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if [[ $(echo "$PYTHON_VERSION >= 3.11" | bc -l) -eq 1 ]]; then
            PYTHON_CMD="python3"
        else
            echo "❌ Python 3.11+ is required. Found Python $PYTHON_VERSION"
            echo "Please install Python 3.11 or higher"
            exit 1
        fi
    else
        echo "❌ Python 3.11+ is required but not installed."
        echo "Please install Python 3.11 or higher"
        exit 1
    fi
}

# Function to check Node.js version
check_node_version() {
    if ! command_exists npm; then
        echo "❌ Node.js and npm are required but not installed."
        echo "Please install Node.js 16+ and npm"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1)
    
    if [ "$NODE_MAJOR" -lt 16 ]; then
        echo "❌ Node.js 16+ is required. Found Node.js $NODE_VERSION"
        echo "Please install Node.js 16 or higher"
        exit 1
    fi
}

# (Removed) ngrok setup — no longer used

# Function to kill processes on specific ports
kill_port_processes() {
    local port=$1
    local process_name=$2
    
    echo "🔍 Checking for existing processes on port $port..."
    
    # Check if lsof is available
    if ! command_exists lsof; then
        echo "⚠️  lsof not available, trying alternative method..."
        # Alternative method using netstat (if available)
        if command_exists netstat; then
            local pids=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | sort -u)
        else
            echo "⚠️  Neither lsof nor netstat available. Skipping port cleanup."
            return 0
        fi
    else
        # Find processes using the port with lsof
        local pids=$(lsof -ti:$port 2>/dev/null)
    fi
    
    if [ -n "$pids" ]; then
        echo "⚠️  Found existing $process_name processes on port $port: $pids"
        echo "🛑 Killing existing processes..."
        
        # Kill processes gracefully first
        echo "$pids" | xargs kill -TERM 2>/dev/null
        
        # Wait a moment for graceful shutdown
        sleep 2
        
        # Force kill if still running
        if command_exists lsof; then
            local remaining_pids=$(lsof -ti:$port 2>/dev/null)
        else
            local remaining_pids=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | sort -u)
        fi
        
        if [ -n "$remaining_pids" ]; then
            echo "🔨 Force killing remaining processes: $remaining_pids"
            echo "$remaining_pids" | xargs kill -9 2>/dev/null
        fi
        
        echo "✅ Cleared port $port"
    else
        echo "✅ Port $port is available"
    fi
}

# Check dependencies
echo "📋 Checking dependencies..."
check_python_version
check_node_version

# Always run locally (ngrok removed)
USE_NGROK=false
echo "✅ Running locally only"

# Kill existing processes on required ports
echo ""
echo "🧹 Cleaning up existing processes..."
kill_port_processes 5000 "backend"
kill_port_processes 3000 "frontend"

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Backend setup
echo ""
echo "🐍 Setting up Flask backend..."
cd "$SCRIPT_DIR/backend"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment with $PYTHON_CMD..."
    $PYTHON_CMD -m venv venv
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create virtual environment"
        exit 1
    fi
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install/upgrade dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

# Check if .env file exists, if not copy from example
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        echo "📋 Creating .env file from env.example..."
        cp env.example .env
        echo "⚠️  Please update .env file with your configuration before production deployment"
    else
        echo "⚠️  No .env file found. Using default configuration"
    fi
fi

# Initialize database
echo "🗄️  Initializing database..."
$PYTHON_CMD -c "
import sys
sys.path.append('.')
from app import init_db
init_db()
print('Database initialized successfully')
"

echo "Backend starting on http://localhost:5000"
nohup $PYTHON_CMD app.py > ../backend.log 2>&1 &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 5

# Check if backend started successfully
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ Backend failed to start"
    exit 1
fi

echo "✅ Backend is running (PID: $BACKEND_PID)"

# Frontend setup
echo ""
echo "⚛️  Setting up React frontend..."
cd "$SCRIPT_DIR/frontend"

# Install/update dependencies
echo "Installing npm dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install npm dependencies"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# Check if frontend can build
echo "Building frontend..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "Frontend starting on http://localhost:3000"
nohup npm start > ../frontend.log 2>&1 &
FRONTEND_PID=$!

# Wait a moment for frontend to start
sleep 8

# Check if frontend started successfully
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "❌ Frontend failed to start"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "✅ Frontend is running (PID: $FRONTEND_PID)"

# (Removed) ngrok start — no longer used
NGROK_PID=""
NGROK_URL=""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down application..."
    echo "Stopping backend (PID: $BACKEND_PID)..."
    kill $BACKEND_PID 2>/dev/null
    echo "Stopping frontend (PID: $FRONTEND_PID)..."
    kill $FRONTEND_PID 2>/dev/null
    
    # ngrok removed
    
    # Wait for processes to terminate gracefully
    sleep 2
    
    # Force kill if still running
    kill -9 $BACKEND_PID 2>/dev/null
    kill -9 $FRONTEND_PID 2>/dev/null
    # ngrok removed
    
    echo "✅ Application stopped successfully"
    exit
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

echo ""
echo "🎉 Application started successfully!"
echo ""
echo "📱 Frontend: http://localhost:3000"
echo "🔗 Backend API: http://localhost:5000"
echo "📊 Health Check: http://localhost:5000/api/health"
echo ""

# ngrok removed

echo ""
echo "📋 Process IDs:"
echo "   Backend PID: $BACKEND_PID"
echo "   Frontend PID: $FRONTEND_PID"
  # ngrok removed

echo ""
echo "📝 Log files:"
echo "   Backend: backend.log"
echo "   Frontend: frontend.log"
  # ngrok removed

echo ""
echo "Press Ctrl+C to stop all servers"
echo ""

# Wait for both processes
wait
