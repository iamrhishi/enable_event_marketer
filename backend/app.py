from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv
import os
import logging
from datetime import datetime
from werkzeug.exceptions import BadRequest

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///events.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize extensions
db = SQLAlchemy(app)
CORS(app, origins=os.getenv('CORS_ORIGINS', 'http://localhost:3000').split(','))
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=["200 per day", "50 per hour"]
)

# Configure logging
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database Models
class Event(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    date = db.Column(db.Date, nullable=False)
    location = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'date': self.date.isoformat(),
            'location': self.location,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

# Input validation
def validate_event_data(data):
    """Validate event data"""
    if not data:
        raise BadRequest('No data provided')
    
    required_fields = ['title', 'description', 'date', 'location']
    missing_fields = [field for field in required_fields if not data.get(field)]
    
    if missing_fields:
        raise BadRequest(f'Missing required fields: {", ".join(missing_fields)}')
    
    # Validate title length
    if len(data['title']) > 200:
        raise BadRequest('Title must be 200 characters or less')
    
    # Validate location length
    if len(data['location']) > 200:
        raise BadRequest('Location must be 200 characters or less')
    
    # Validate date format
    try:
        datetime.strptime(data['date'], '%Y-%m-%d')
    except ValueError:
        raise BadRequest('Date must be in YYYY-MM-DD format')
    
    return True

# Error handlers
@app.errorhandler(BadRequest)
def handle_bad_request(error):
    logger.warning(f'Bad request: {error.description}')
    return jsonify({
        'success': False,
        'message': error.description
    }), 400

@app.errorhandler(404)
def handle_not_found(error):
    logger.warning(f'Not found: {request.url}')
    return jsonify({
        'success': False,
        'message': 'Resource not found'
    }), 404

@app.errorhandler(500)
def handle_internal_error(error):
    logger.error(f'Internal server error: {error}')
    return jsonify({
        'success': False,
        'message': 'Internal server error'
    }), 500

# Routes
@app.route('/')
def home():
    logger.info('Health check endpoint accessed')
    return jsonify({
        'message': 'Welcome to Event Marketer API',
        'status': 'running',
        'version': '1.0.0'
    })

@app.route('/api/events', methods=['GET'])
@limiter.limit("30 per minute")
def get_events():
    try:
        events = Event.query.all()
        logger.info(f'Retrieved {len(events)} events')
        return jsonify({
            'success': True,
            'data': [event.to_dict() for event in events]
        })
    except Exception as e:
        logger.error(f'Error retrieving events: {e}')
        return jsonify({
            'success': False,
            'message': 'Failed to retrieve events'
        }), 500

@app.route('/api/events', methods=['POST'])
@limiter.limit("10 per minute")
def create_event():
    try:
        data = request.get_json()
        validate_event_data(data)
        
        # Parse date
        event_date = datetime.strptime(data['date'], '%Y-%m-%d').date()
        
        new_event = Event(
            title=data['title'],
            description=data['description'],
            date=event_date,
            location=data['location']
        )
        
        db.session.add(new_event)
        db.session.commit()
        
        logger.info(f'Created new event: {new_event.title}')
        return jsonify({
            'success': True,
            'data': new_event.to_dict()
        }), 201
        
    except BadRequest as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 400
    except Exception as e:
        logger.error(f'Error creating event: {e}')
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': 'Failed to create event'
        }), 500

@app.route('/api/events/<int:event_id>', methods=['GET'])
@limiter.limit("30 per minute")
def get_event(event_id):
    try:
        event = Event.query.get(event_id)
        if not event:
            logger.warning(f'Event {event_id} not found')
            return jsonify({
                'success': False,
                'message': 'Event not found'
            }), 404
        
        logger.info(f'Retrieved event: {event.title}')
        return jsonify({
            'success': True,
            'data': event.to_dict()
        })
    except Exception as e:
        logger.error(f'Error retrieving event {event_id}: {e}')
        return jsonify({
            'success': False,
            'message': 'Event not found'
        }), 404

@app.route('/api/events/<int:event_id>', methods=['PUT'])
@limiter.limit("10 per minute")
def update_event(event_id):
    try:
        event = Event.query.get(event_id)
        if not event:
            logger.warning(f'Event {event_id} not found for update')
            return jsonify({
                'success': False,
                'message': 'Event not found'
            }), 404
            
        data = request.get_json()
        
        if not data:
            raise BadRequest('No data provided')
        
        # Update fields if provided
        if 'title' in data:
            if len(data['title']) > 200:
                raise BadRequest('Title must be 200 characters or less')
            event.title = data['title']
        
        if 'description' in data:
            event.description = data['description']
        
        if 'date' in data:
            try:
                event.date = datetime.strptime(data['date'], '%Y-%m-%d').date()
            except ValueError:
                raise BadRequest('Date must be in YYYY-MM-DD format')
        
        if 'location' in data:
            if len(data['location']) > 200:
                raise BadRequest('Location must be 200 characters or less')
            event.location = data['location']
        
        event.updated_at = datetime.utcnow()
        db.session.commit()
        
        logger.info(f'Updated event: {event.title}')
        return jsonify({
            'success': True,
            'data': event.to_dict()
        })
        
    except BadRequest as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 400
    except Exception as e:
        logger.error(f'Error updating event {event_id}: {e}')
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': 'Failed to update event'
        }), 500

@app.route('/api/events/<int:event_id>', methods=['DELETE'])
@limiter.limit("10 per minute")
def delete_event(event_id):
    try:
        event = Event.query.get(event_id)
        if not event:
            logger.warning(f'Event {event_id} not found for deletion')
            return jsonify({
                'success': False,
                'message': 'Event not found'
            }), 404
            
        event_title = event.title
        
        db.session.delete(event)
        db.session.commit()
        
        logger.info(f'Deleted event: {event_title}')
        return jsonify({
            'success': True,
            'message': 'Event deleted successfully'
        })
        
    except Exception as e:
        logger.error(f'Error deleting event {event_id}: {e}')
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': 'Failed to delete event'
        }), 500

# Initialize database
def init_db():
    """Initialize database with sample data"""
    with app.app_context():
        db.create_all()
        
        # Check if we already have data
        if Event.query.count() == 0:
            sample_events = [
                Event(
                    title='Tech Conference 2024',
                    description='Annual technology conference featuring latest innovations',
                    date=datetime(2024, 10, 15).date(),
                    location='San Francisco, CA'
                ),
                Event(
                    title='Marketing Workshop',
                    description='Learn effective marketing strategies for modern businesses',
                    date=datetime(2024, 11, 20).date(),
                    location='New York, NY'
                )
            ]
            
            for event in sample_events:
                db.session.add(event)
            
            db.session.commit()
            logger.info('Database initialized with sample data')

# Health check endpoint for deployment platforms
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'Enable Event Marketer API'
    })

if __name__ == '__main__':
    init_db()
    
    # Get configuration from environment
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f'Starting server on {host}:{port} (debug={debug})')
    app.run(host=host, port=port, debug=debug)
