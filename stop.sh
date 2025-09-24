#!/bin/bash

# Stop script for Event Marketer Application
echo "🛑 Stopping Event Marketer Application..."

# Function to kill processes on specific ports
kill_port_processes() {
    local port=$1
    local process_name=$2
    
    echo "🔍 Checking for $process_name processes on port $port..."
    
    # Check if lsof is available
    if ! command -v lsof >/dev/null 2>&1; then
        echo "⚠️  lsof not available, trying alternative method..."
        # Alternative method using netstat (if available)
        if command -v netstat >/dev/null 2>&1; then
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
        echo "🛑 Found $process_name processes on port $port: $pids"
        echo "   Killing processes..."
        
        # Kill processes gracefully first
        echo "$pids" | xargs kill -TERM 2>/dev/null
        
        # Wait a moment for graceful shutdown
        sleep 2
        
        # Force kill if still running
        if command -v lsof >/dev/null 2>&1; then
            local remaining_pids=$(lsof -ti:$port 2>/dev/null)
        else
            local remaining_pids=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | sort -u)
        fi
        
        if [ -n "$remaining_pids" ]; then
            echo "🔨 Force killing remaining processes: $remaining_pids"
            echo "$remaining_pids" | xargs kill -9 2>/dev/null
        fi
        
        echo "✅ Stopped $process_name on port $port"
    else
        echo "✅ No $process_name processes found on port $port"
    fi
}

# Kill screen sessions first (if they exist)
echo ""
echo "🧹 Stopping services..."
if command -v screen >/dev/null 2>&1; then
    echo "🔍 Checking for screen sessions..."
    if screen -list | grep -q "backend"; then
        echo "🛑 Stopping backend screen session..."
        screen -S backend -X quit
    fi
    if screen -list | grep -q "frontend"; then
        echo "🛑 Stopping frontend screen session..."
        screen -S frontend -X quit
    fi
fi

# Kill processes on required ports
kill_port_processes 5000 "backend"
kill_port_processes 3001 "frontend"

echo ""
echo "✅ Application stopped successfully!"
echo ""
echo "📝 Log files are still available:"
echo "   Backend: backend.log"
echo "   Frontend: frontend.log"
echo ""
