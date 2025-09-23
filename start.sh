#!/bin/bash

# Start script for Event Marketer Application
echo "🚀 Starting Event Marketer Application..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "📋 Checking dependencies..."
if ! command_exists python3; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

if ! command_exists npm; then
    echo "❌ Node.js and npm are required but not installed."
    exit 1
fi

echo "✅ Dependencies check passed!"

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Start backend
echo "🐍 Starting Flask backend..."
cd "$SCRIPT_DIR/backend"
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install -r requirements.txt

echo "Backend starting on http://localhost:5000"
python app.py &
BACKEND_PID=$!

# Start frontend
echo "⚛️  Starting React frontend..."
cd "$SCRIPT_DIR/frontend"
if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
fi

echo "Frontend starting on http://localhost:3000"
npm start &
FRONTEND_PID=$!

# Function to cleanup on exit
cleanup() {
    echo "🛑 Shutting down application..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit
}

# Set trap to cleanup on script exit
trap cleanup SIGINT

echo "🎉 Application started successfully!"
echo "📱 Frontend: http://localhost:3000"
echo "🔗 Backend API: http://localhost:5000"
echo "Press Ctrl+C to stop both servers"

# Wait for both processes
wait
