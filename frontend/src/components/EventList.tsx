import React, { useState, useEffect } from 'react';
import eventService, { Event } from '../services/eventService';
import './EventList.css';

const EventList: React.FC = () => {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<boolean>(false);

  useEffect(() => {
    checkBackendConnection();
    fetchEvents();
  }, []);

  const checkBackendConnection = async () => {
    const isConnected = await eventService.checkConnection();
    setConnectionStatus(isConnected);
  };

  const fetchEvents = async () => {
    try {
      setLoading(true);
      const eventsData = await eventService.getAllEvents();
      setEvents(eventsData);
      setError(null);
    } catch (err) {
      setError('Failed to fetch events. Make sure the backend server is running on http://localhost:5000');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteEvent = async (id: number) => {
    try {
      await eventService.deleteEvent(id);
      setEvents(events.filter(event => event.id !== id));
    } catch (err) {
      setError('Failed to delete event');
    }
  };

  if (loading) {
    return <div className="loading">Loading events...</div>;
  }

  return (
    <div className="event-list-container">
      <div className="header">
        <h1>Event Marketer</h1>
        <div className={`connection-status ${connectionStatus ? 'connected' : 'disconnected'}`}>
          Backend: {connectionStatus ? '🟢 Connected' : '🔴 Disconnected'}
        </div>
      </div>

      {error && (
        <div className="error-message">
          {error}
          <button onClick={fetchEvents} className="retry-button">
            Retry
          </button>
        </div>
      )}

      <div className="events-grid">
        {events.length === 0 ? (
          <div className="no-events">
            <p>No events found.</p>
            {connectionStatus && (
              <p>The backend is connected and ready to receive new events!</p>
            )}
          </div>
        ) : (
          events.map((event) => (
            <div key={event.id} className="event-card">
              <div className="event-header">
                <h3>{event.title}</h3>
                <button
                  onClick={() => handleDeleteEvent(event.id)}
                  className="delete-button"
                  title="Delete event"
                >
                  ×
                </button>
              </div>
              <p className="event-description">{event.description}</p>
              <div className="event-details">
                <p><strong>Date:</strong> {new Date(event.date).toLocaleDateString()}</p>
                <p><strong>Location:</strong> {event.location}</p>
              </div>
            </div>
          ))
        )}
      </div>

      <div className="add-event-info">
        <p>
          To test the connection, you can create new events by making POST requests to:
          <br />
          <code>http://localhost:5000/api/events</code>
        </p>
      </div>
    </div>
  );
};

export default EventList;
