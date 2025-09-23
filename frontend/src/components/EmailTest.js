// Email Test Component
// This component can be used to test email functionality

import React, { useState } from 'react';
import { sendUseCaseEmail, sendEngagementEmail } from '../services/emailService';
import procurementUsecases from '../data/procurement.json';

const EmailTest = () => {
  const [testEmail, setTestEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState('');

  const testUseCaseEmail = async () => {
    if (!testEmail) {
      setResult('Please enter a test email address');
      return;
    }

    setIsLoading(true);
    setResult('Sending test email...');

    try {
      // Use the first use case for testing
      const testUseCase = procurementUsecases[0];
      const emailResult = await sendUseCaseEmail(testEmail, testUseCase);
      
      if (emailResult.success) {
        setResult('✅ Test email sent successfully! Check engineering@enableyou.co');
      } else {
        setResult('❌ Failed to send email: ' + emailResult.error);
      }
    } catch (error) {
      setResult('❌ Error: ' + error.message);
    }

    setIsLoading(false);
  };

  const testEngagementEmail = async () => {
    if (!testEmail) {
      setResult('Please enter a test email address');
      return;
    }

    setIsLoading(true);
    setResult('Sending engagement email...');

    try {
      const emailResult = await sendEngagementEmail(testEmail, 'test_engagement');
      
      if (emailResult.success) {
        setResult('✅ Engagement email sent successfully! Check engineering@enableyou.co');
      } else {
        setResult('❌ Failed to send email: ' + emailResult.error);
      }
    } catch (error) {
      setResult('❌ Error: ' + error.message);
    }

    setIsLoading(false);
  };

  return (
    <div style={{ padding: '20px', border: '1px solid #ccc', margin: '20px' }}>
      <h3>Email Functionality Test</h3>
      
      <div style={{ marginBottom: '10px' }}>
        <label>Test Email Address: </label>
        <input
          type="email"
          value={testEmail}
          onChange={(e) => setTestEmail(e.target.value)}
          placeholder="Enter test email address"
          style={{ marginLeft: '10px', padding: '5px' }}
        />
      </div>

      <div style={{ marginBottom: '10px' }}>
        <button 
          onClick={testUseCaseEmail} 
          disabled={isLoading}
          style={{ marginRight: '10px', padding: '8px 16px' }}
        >
          Test Use Case Email
        </button>
        
        <button 
          onClick={testEngagementEmail} 
          disabled={isLoading}
          style={{ padding: '8px 16px' }}
        >
          Test Engagement Email
        </button>
      </div>

      {result && (
        <div style={{ 
          padding: '10px', 
          backgroundColor: result.includes('✅') ? '#d4edda' : '#f8d7da',
          border: `1px solid ${result.includes('✅') ? '#c3e6cb' : '#f5c6cb'}`,
          borderRadius: '4px'
        }}>
          {result}
        </div>
      )}

      <div style={{ marginTop: '20px', fontSize: '14px', color: '#666' }}>
        <h4>What gets sent to engineering@enableyou.co:</h4>
        <ul>
          <li>User's email address</li>
          <li>Use case title, outcome, problem, solution</li>
          <li>Personas and categories</li>
          <li>Timestamp and page URL</li>
          <li>User agent information</li>
        </ul>
      </div>
    </div>
  );
};

export default EmailTest;
