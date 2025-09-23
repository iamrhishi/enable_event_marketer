import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

export interface Event {
  id: number;
  title: string;
  description: string;
  date: string;
  location: string;
  created_at?: string;
  updated_at?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
}

class EventService {
  private api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  async getAllEvents(): Promise<Event[]> {
    try {
      const response = await this.api.get<ApiResponse<Event[]>>('/events');
      return response.data.data || [];
    } catch (error) {
      console.error('Error fetching events:', error);
      throw error;
    }
  }

  async getEvent(id: number): Promise<Event> {
    try {
      const response = await this.api.get<ApiResponse<Event>>(`/events/${id}`);
      if (!response.data.data) {
        throw new Error('Event not found');
      }
      return response.data.data;
    } catch (error) {
      console.error('Error fetching event:', error);
      throw error;
    }
  }

  async createEvent(event: Omit<Event, 'id'>): Promise<Event> {
    try {
      const response = await this.api.post<ApiResponse<Event>>('/events', event);
      if (!response.data.data) {
        throw new Error('Failed to create event');
      }
      return response.data.data;
    } catch (error) {
      console.error('Error creating event:', error);
      throw error;
    }
  }

  async updateEvent(id: number, event: Partial<Omit<Event, 'id'>>): Promise<Event> {
    try {
      const response = await this.api.put<ApiResponse<Event>>(`/events/${id}`, event);
      if (!response.data.data) {
        throw new Error('Failed to update event');
      }
      return response.data.data;
    } catch (error) {
      console.error('Error updating event:', error);
      throw error;
    }
  }

  async deleteEvent(id: number): Promise<void> {
    try {
      await this.api.delete(`/events/${id}`);
    } catch (error) {
      console.error('Error deleting event:', error);
      throw error;
    }
  }

  async checkConnection(): Promise<boolean> {
    try {
      const response = await axios.get('http://localhost:5000/');
      return response.status === 200;
    } catch (error) {
      return false;
    }
  }
}

const eventService = new EventService();
export default eventService;
