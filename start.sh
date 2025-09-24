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

# Function to kill processes on specific ports
kill_port_processes() {
    local port=$1
    local process_name=$2
    
    echo "🔍 Checking for existing processes on port $port..."
    
    if command_exists lsof; then
        local pids=$(lsof -ti:$port 2>/dev/null)
    elif command_exists netstat; then
        local pids=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | sort -u)
    else
        echo "⚠️  Neither lsof nor netstat available. Skipping port cleanup."
        return 0
    fi
    
    if [ -n "$pids" ]; then
        echo "⚠️  Found existing $process_name processes on port $port: $pids"
        echo "🛑 Killing existing processes..."
        echo "$pids" | xargs kill -TERM 2>/dev/null
        sleep 2
        echo "$pids" | xargs kill -9 2>/dev/null
        echo "✅ Cleared port $port"
    else
        echo "✅ Port $port is available"
    fi
}

# Check dependencies
echo "📋 Checking dependencies..."
check_python_version
check_node_version

# Kill existing processes on required ports
echo ""
echo "🧹 Cleaning up existing processes..."
kill_port_processes 5000 "backend"
kill_port_processes 3001 "frontend"

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Start backend
echo ""
echo "🐍 Starting Flask backend..."
cd "$SCRIPT_DIR/backend"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    $PYTHON_CMD -m venv venv
fi

# Activate virtual environment and start backend
source venv/bin/activate
pip install --upgrade pip >/dev/null 2>&1
pip install -r requirements.txt >/dev/null 2>&1

# Initialize database
$PYTHON_CMD -c "
import sys
sys.path.append('.')
from app import init_db
init_db()
print('Database initialized successfully')
" >/dev/null 2>&1

# Start backend using screen (if available) or nohup
if command_exists screen; then
    screen -dmS backend $PYTHON_CMD app.py
    echo "✅ Backend started in screen session 'backend'"
    BACKEND_PID="screen session"
else
    nohup $PYTHON_CMD app.py > ../backend.log 2>&1 &
    BACKEND_PID=$!
    echo "✅ Backend started (PID: $BACKEND_PID)"
fi

# Start frontend
echo "⚛️  Starting React frontend..."
cd "$SCRIPT_DIR/frontend"

# Install dependencies and build
npm install >/dev/null 2>&1
npm run build >/dev/null 2>&1

# Start frontend using screen (if available) or nohup
if command_exists screen; then
    screen -dmS frontend PORT=3001 npm start
    echo "✅ Frontend started in screen session 'frontend'"
    FRONTEND_PID="screen session"
else
    nohup PORT=3001 npm start > ../frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "✅ Frontend started (PID: $FRONTEND_PID)"
fi

# Give services a moment to start
sleep 2

echo ""
echo "🎉 Application started successfully!"
echo ""
echo "📱 Frontend: http://localhost:3001"
echo "🔗 Backend API: http://localhost:5000"
echo "📊 Health Check: http://localhost:5000/api/health"
echo ""
echo "📋 Process IDs:"
echo "   Backend: $BACKEND_PID"
echo "   Frontend: $FRONTEND_PID"
echo ""
echo "📝 Log files:"
echo "   Backend: backend.log"
echo "   Frontend: frontend.log"
echo ""
echo "✅ Services are running in the background"
echo "   Use './stop.sh' to stop all services"
echo ""

# Exit immediately
exit 0