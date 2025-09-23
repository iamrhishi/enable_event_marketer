import React from 'react';
import EventNetworkingAgent from './components/EventNetworkingAgent';
import ErrorBoundary from './components/ErrorBoundary';
import { NotificationProvider } from './components/Notification';
import './App.css';

function App() {
  return (
    <ErrorBoundary>
      <NotificationProvider>
        <div className="App">
          <EventNetworkingAgent />
        </div>
      </NotificationProvider>
    </ErrorBoundary>
  );
}

export default App;
