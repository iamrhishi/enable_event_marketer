from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Sample data (in a real app, this would be a database)
events = [
    {
        'id': 1,
        'title': 'Tech Conference 2024',
        'description': 'Annual technology conference featuring latest innovations',
        'date': '2024-10-15',
        'location': 'San Francisco, CA'
    },
    {
        'id': 2,
        'title': 'Marketing Workshop',
        'description': 'Learn effective marketing strategies for modern businesses',
        'date': '2024-11-20',
        'location': 'New York, NY'
    }
]

@app.route('/')
def home():
    return jsonify({
        'message': 'Welcome to Event Marketer API',
        'status': 'running'
    })

@app.route('/api/events', methods=['GET'])
def get_events():
    return jsonify({
        'success': True,
        'data': events
    })

@app.route('/api/events', methods=['POST'])
def create_event():
    data = request.get_json()
    
    if not data or not all(key in data for key in ['title', 'description', 'date', 'location']):
        return jsonify({
            'success': False,
            'message': 'Missing required fields: title, description, date, location'
        }), 400
    
    new_event = {
        'id': len(events) + 1,
        'title': data['title'],
        'description': data['description'],
        'date': data['date'],
        'location': data['location']
    }
    
    events.append(new_event)
    
    return jsonify({
        'success': True,
        'data': new_event
    }), 201

@app.route('/api/events/<int:event_id>', methods=['GET'])
def get_event(event_id):
    event = next((e for e in events if e['id'] == event_id), None)
    
    if not event:
        return jsonify({
            'success': False,
            'message': 'Event not found'
        }), 404
    
    return jsonify({
        'success': True,
        'data': event
    })

@app.route('/api/events/<int:event_id>', methods=['PUT'])
def update_event(event_id):
    data = request.get_json()
    event = next((e for e in events if e['id'] == event_id), None)
    
    if not event:
        return jsonify({
            'success': False,
            'message': 'Event not found'
        }), 404
    
    # Update event fields if provided
    if 'title' in data:
        event['title'] = data['title']
    if 'description' in data:
        event['description'] = data['description']
    if 'date' in data:
        event['date'] = data['date']
    if 'location' in data:
        event['location'] = data['location']
    
    return jsonify({
        'success': True,
        'data': event
    })

@app.route('/api/events/<int:event_id>', methods=['DELETE'])
def delete_event(event_id):
    global events
    event = next((e for e in events if e['id'] == event_id), None)
    
    if not event:
        return jsonify({
            'success': False,
            'message': 'Event not found'
        }), 404
    
    events = [e for e in events if e['id'] != event_id]
    
    return jsonify({
        'success': True,
        'message': 'Event deleted successfully'
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
