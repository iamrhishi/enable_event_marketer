# Event Marketer Application

A full-stack web application built with React.js frontend and Flask backend for managing events.

## 🏗️ Project Structure

```
enable_event_marketer/
├── frontend/          # React.js frontend application
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── services/      # API service layer
│   │   └── ...
│   ├── package.json
│   └── ...
├── backend/           # Flask backend API
│   ├── app.py            # Main Flask application
│   ├── requirements.txt  # Python dependencies
│   ├── venv/            # Python virtual environment
│   └── ...
├── start.sh          # Startup script for both frontend and backend
└── README.md         # This file
```

## 🚀 Quick Start

### Option 1: Use the startup script (Recommended)
```bash
./start.sh
```

### Option 2: Manual startup

#### Backend (Flask)
```bash
cd backend
source venv/bin/activate
python app.py
```

#### Frontend (React)
```bash
cd frontend
npm start
```

## 📋 Prerequisites

- **Python 3.11+** - For the Flask backend
- **Node.js 16+** - For the React frontend
- **npm** - Node package manager

## 🔧 Installation

### Backend Setup
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Frontend Setup
```bash
cd frontend
npm install
```

## 🖥️ Usage

1. Start both servers using `./start.sh` or manually
2. Open http://localhost:3000 in your browser
3. The frontend will show the connection status to the backend
4. View sample events loaded from the backend
5. Use the API endpoints to manage events

## 🔗 API Endpoints

Base URL: `http://localhost:5000/api`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Health check |
| GET | `/api/events` | Get all events |
| POST | `/api/events` | Create a new event |
| GET | `/api/events/:id` | Get event by ID |
| PUT | `/api/events/:id` | Update event by ID |
| DELETE | `/api/events/:id` | Delete event by ID |

### Example API Usage

#### Create a new event
```bash
curl -X POST http://localhost:5000/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Event",
    "description": "Event description",
    "date": "2024-12-01",
    "location": "Event Location"
  }'
```

#### Get all events
```bash
curl http://localhost:5000/api/events
```

## 🛠️ Technology Stack

### Frontend
- **React.js** - UI library
- **TypeScript** - Type safety
- **Axios** - HTTP client
- **CSS3** - Styling

### Backend
- **Flask** - Web framework
- **Flask-CORS** - Cross-origin resource sharing
- **Python 3.11+** - Programming language

## 🔄 Development

### Frontend Development
```bash
cd frontend
npm start          # Start development server
npm test           # Run tests
npm run build      # Build for production
```

### Backend Development
```bash
cd backend
source venv/bin/activate
python app.py      # Start development server with auto-reload
```

## 🌐 CORS Configuration

The backend is configured with CORS to allow requests from the React frontend running on `http://localhost:3000`. This enables seamless communication between the frontend and backend during development.

## 📂 Key Files

- `backend/app.py` - Main Flask application with API routes
- `frontend/src/services/eventService.ts` - Frontend API service
- `frontend/src/components/EventList.tsx` - Main React component
- `start.sh` - Startup script for the entire application

## 🐛 Troubleshooting

### Backend not connecting
- Ensure Python virtual environment is activated
- Check that Flask dependencies are installed: `pip install -r requirements.txt`
- Verify the backend is running on port 5000

### Frontend issues
- Ensure npm dependencies are installed: `npm install`
- Check that the React app is running on port 3000
- Verify the frontend can reach the backend API

### CORS errors
- The backend includes Flask-CORS configuration
- If you still see CORS errors, check that both servers are running on the correct ports

## 🚧 Future Enhancements

- Add user authentication
- Implement event categories
- Add event image uploads
- Include event search and filtering
- Add event registration functionality
- Implement real database (PostgreSQL/MongoDB)

## 📝 License

This project is open source and available under the [MIT License](LICENSE).
