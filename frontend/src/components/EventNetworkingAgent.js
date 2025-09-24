import React, { useState } from 'react';
import procurementUsecases from '../data/procurement.json';
import procurementAiUsecases from '../data/procurement_ai_usecases.json';
import { FaLinkedin, FaEnvelope, FaGlobe } from 'react-icons/fa';
import { useNotification } from './Notification';
import { sendUseCaseEmail, sendFallbackEmail } from '../services/emailService';
import '../styles/EventNetworkingAgent.css';
import '../styles/Notification.css';



function getLoggedInUsername() {
  return localStorage.getItem('firstName') || 'Enable User';
}
function getLoggedInLinkedin() {
  return localStorage.getItem('linkedin') || 'http://linkedin.com/in/rhishikesh-thakur';
}
function getLoggedInEmail() {
  return localStorage.getItem('email') || 'hello@enableai.com';
}

const defaultIntro = (
  <div className="agent-details">
      <h3>Hey there! It's {getLoggedInUsername() || 'Enable User'}. Great that we are connecting! </h3>
  </div>
);

const topics = [
  'High-RoI AI Use Cases',
  'Data Discovery Agent',
  'Agentic Business Modules',
  'Faster ROI Strategy'
];

function EventNetworkingAgent() {
  const { showNotification } = useNotification();
  const [chat] = useState([
    { sender: 'agent', content: defaultIntro },
    { sender: 'agent', content: (
      <div>
        <div className="agent-details">
          <h3>
           We just want to share our learning and also learn from you!
          </h3>
        </div>
      </div>
    )},
    { sender: 'agent', content: (
      <div className="topic-options">
        {topics.map((topic, idx) => (
          <button
            key={topic}
            className="topic-btn"
            onClick={() => handleTopicSelect(topic)}
          >
            {topic}
          </button>
        ))}
      </div>
    )}
  ]);
  const [currentPage, setCurrentPage] = useState('main'); // 'main' or 'usecases'
  const [usecaseIndex, setUsecaseIndex] = useState(0);
  const [shareEmail, setShareEmail] = useState(() => {
    // Initialize with saved email if available
    return localStorage.getItem('enable_user_email') || '';
  });
  const [hasValidEmail, setHasValidEmail] = useState(() => {
    // Check localStorage on component mount
    const savedEmail = localStorage.getItem('enable_user_email');
    const savedUnlockStatus = localStorage.getItem('enable_content_unlocked');
    return savedEmail && savedUnlockStatus === 'true';
  });
  const [isEmailSending, setIsEmailSending] = useState(false);
  const [showUnlockedNotification, setShowUnlockedNotification] = useState(false);
  const [touchStart, setTouchStart] = useState(null);
  const [touchEnd, setTouchEnd] = useState(null);
  const [selectedTopic, setSelectedTopic] = useState('High-RoI AI Use Cases');

  // Minimum distance for swipe detection - more sensitive
  const minSwipeDistance = 30;

  // Function to get use cases data based on selected topic
  const getUsecasesData = () => {
    switch (selectedTopic) {
      case 'High-RoI AI Use Cases':
        return procurementUsecases;
      case 'Data Discovery Agent':
        return procurementAiUsecases['Data Discovery Agent'] || [];
      case 'Agentic Business Modules':
        return procurementAiUsecases['Agentic Business Modules'] || [];
      case 'Faster ROI Strategy':
        return procurementAiUsecases['Faster ROI Strategy'] || [];
      default:
        return procurementUsecases;
    }
  };

  const onTouchStart = (e) => {
    setTouchEnd(null);
    setTouchStart(e.targetTouches[0].clientX);
  };

  const onTouchMove = (e) => {
    setTouchEnd(e.targetTouches[0].clientX);
  };

  const onTouchEnd = () => {
    if (!touchStart || !touchEnd) return;
    
    const distance = touchStart - touchEnd;
    const isLeftSwipe = distance > minSwipeDistance;
    const isRightSwipe = distance < -minSwipeDistance;

    if (isLeftSwipe) {
      handleNextUsecase();
    } else if (isRightSwipe) {
      handlePrevUsecase();
    }
  };

  const validateEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };


  const handleEmailChange = (e) => {
    const email = e.target.value;
    setShareEmail(email);
    // Don't unlock content automatically - only on Enter key
  };

  const handleEmailKeyPress = async (e) => {
    if (e.key === 'Enter') {
      const email = e.target.value;
      if (!email || !validateEmail(email)) {
        showNotification('Please enter a valid email address.', 'error');
        return;
      }
      
      setIsEmailSending(true);
      
      try {
        const currentUseCase = getUsecasesData()[usecaseIndex];
        const emailResult = await sendUseCaseEmail(email, currentUseCase);
        
        if (emailResult.success) {
          // Email sent successfully - unlock content
          setHasValidEmail(true);
          localStorage.setItem('enable_user_email', email);
          localStorage.setItem('enable_content_unlocked', 'true');
          showNotification('Email sent successfully! Content unlocked.', 'success');
          
          // Show unlocked notification temporarily
          setShowUnlockedNotification(true);
          setTimeout(() => {
            setShowUnlockedNotification(false);
          }, 3000); // Hide after 3 seconds
        } else {
          // Email failed - show error and don't unlock
          showNotification('Failed to send email. Please check your email address and try again.', 'error');
        }
      } catch (error) {
        console.error('Email sending failed:', error);
        showNotification('Failed to send email. Please check your email address and try again.', 'error');
      } finally {
        setIsEmailSending(false);
      }
    }
  };

  const handleShare = async () => {
    if (!shareEmail || !validateEmail(shareEmail)) {
      showNotification('Please enter a valid email address.', 'error');
      return;
    }
    
    setIsEmailSending(true);
    
    try {
      const currentUseCase = procurementUsecases[usecaseIndex];
      const emailResult = await sendUseCaseEmail(shareEmail, currentUseCase);
      
      if (emailResult.success) {
        // Email sent successfully - unlock content
        setHasValidEmail(true);
        localStorage.setItem('enable_user_email', shareEmail);
        localStorage.setItem('enable_content_unlocked', 'true');
        showNotification('Email sent successfully! Content unlocked.', 'success');
        
        // Show unlocked notification temporarily
        setShowUnlockedNotification(true);
        setTimeout(() => {
          setShowUnlockedNotification(false);
        }, 3000); // Hide after 3 seconds
        
        setShareEmail('');
      } else {
        // Email failed - show error and don't unlock
        showNotification('Failed to send email. Please check your email address and try again.', 'error');
      }
    } catch (error) {
      console.error('Email sending failed:', error);
      showNotification('Failed to send email. Please check your email address and try again.', 'error');
    } finally {
      setIsEmailSending(false);
    }
  };


  const handleTopicSelect = (topic) => {
    setCurrentPage('usecases');
    setSelectedTopic(topic);
    setUsecaseIndex(0); // Reset to first use case when switching topics
    // Don't add topic to chat to avoid duplicate display
    // Add haptic feedback for mobile devices
    if (navigator.vibrate) {
      navigator.vibrate(50);
    }
  };

  const handleBackToMain = () => {
    setCurrentPage('main');
  };

  const handlePrevUsecase = () => {
    setUsecaseIndex((prev) => (prev > 0 ? prev - 1 : getUsecasesData().length - 1));
  };

  const handleNextUsecase = () => {
    setUsecaseIndex((prev) => (prev < getUsecasesData().length - 1 ? prev + 1 : 0));
  };

  return (
    <div className="event-networking-agent-chat" style={{ position: 'relative' }}>
      <div className="chat-header enable-header">
        <div className="header-flex">
          <img 
            src={process.env.PUBLIC_URL + '/assets/images/enable_logo.png'} 
            alt="Enable Logo" 
            className="header-logo"
            loading="lazy"
          />
          <img 
            src={process.env.PUBLIC_URL + '/assets/icons/ai-technology.png'} 
            alt="AI Technology Logo" 
            className="header-ai-logo"
            loading="lazy"
          />
        </div>
      </div>
      
      {/* Unified Footer - Consistent across all devices */}
      <div className="unified-footer">
        <div className="unified-contact-icons">
          <a 
            href={getLoggedInLinkedin()} 
            target="_blank" 
            rel="noopener noreferrer" 
            title="LinkedIn"
            aria-label="Visit our LinkedIn profile"
          >
            <FaLinkedin />
          </a>
          <a 
            href={`mailto:${getLoggedInEmail()}`} 
            title="Email"
            aria-label="Send us an email"
          >
            <FaEnvelope />
          </a>
          <a 
            href="https://enableyou.co" 
            target="_blank" 
            rel="noopener noreferrer" 
            title="Website"
            aria-label="Visit our website"
          >
            <FaGlobe />
          </a>
        </div>
      </div>
      <div className="chat-body">
        {currentPage === 'main' ? (
          // Main page content
          chat.map((msg, idx) => (
            msg.sender === 'agent' ? (
              <div key={idx} className="chat-row agent">
                <div className="agent-message-with-avatar">
                  <img
                    src={process.env.PUBLIC_URL + '/assets/images/Gemini_Generated_Image_p5j4wqp5j4wqp5j4.png'}
                    alt="Enable AI Agent Avatar"
                    className="agent-avatar"
                    loading="lazy"
                    onError={(e) => {
                      e.target.style.display = 'none';
                    }}
                  />
                  <div className="agent-message-content">
                    {msg.content}
                  </div>
                </div>
              </div>
            ) : (
              <div key={idx} className="chat-row user">{msg.content}</div>
            )
          ))
        ) : (
          // Use cases page content
          <div 
            className="usecases-page"
            onTouchStart={onTouchStart}
            onTouchMove={onTouchMove}
            onTouchEnd={onTouchEnd}
          >
            {/* Back button */}
            <div className="page-header">
              <button 
                className="back-button" 
                onClick={handleBackToMain}
                title="Back to main"
                aria-label="Back to main page"
              >
                ← Back
              </button>
              <h2 className="page-title">{selectedTopic}</h2>
            </div>

            {/* Carousel indicators */}
            <div className="carousel-indicators">
              {getUsecasesData().map((_, index) => (
                <div
                  key={index}
                  className={`carousel-indicator ${index === usecaseIndex ? 'active' : ''}`}
                  onClick={() => setUsecaseIndex(index)}
                  title={`Go to use case ${index + 1}`}
                />
              ))}
            </div>

            {/* Use case content */}
            <div className="usecase-content">
              <h3 className="usecase-title">{getUsecasesData()[usecaseIndex].outcome}</h3>
              <div className="usecase-row usecase-row-highlight">
                <span className="usecase-label usecase-label-main">Use Case:</span>
                <span className="usecase-value usecase-value-main">{getUsecasesData()[usecaseIndex].title}</span>
              </div>
              
              {/* Blurred content that requires email */}
              <div className={`usecase-detailed-content ${!hasValidEmail ? 'blurred' : ''}`}>
                <div className="usecase-row">
                  <span className="usecase-label">Problem:</span>
                  <span className="usecase-value">{getUsecasesData()[usecaseIndex].problem}</span>
                </div>
                <div className="usecase-row">
                  <span className="usecase-label">Solution:</span>
                  <span className="usecase-value">{getUsecasesData()[usecaseIndex].solution}</span>
                </div>
                <div className="usecase-keywords">
                  {getUsecasesData()[usecaseIndex].persona.map((p, i) => (
                    <span className="usecase-keyword" key={i}>{p}</span>
                  ))}
                  {getUsecasesData()[usecaseIndex].category.map((c, i) => (
                    <span className="usecase-keyword" key={i}>{c}</span>
                  ))}
                </div>
              </div>
              
              {/* Email requirement overlay */}
              {!hasValidEmail && (
                <div className="email-requirement-overlay">
                  <div className="email-requirement-content">
                    <h4>Enter your email to unlock detailed insights</h4>
                    <p>Get access to the complete problem analysis, solution details, and key personas for this use case.</p>
                    <p className="enter-hint">Press Enter or click "Unlock Content" to proceed</p>
                    <div className="email-input-section">
                           <input
                             type="email"
                             className="overlay-email-input"
                             placeholder="Enter your email address"
                             value={shareEmail}
                             onChange={handleEmailChange}
                             onKeyPress={handleEmailKeyPress}
                             disabled={isEmailSending}
                           />
                           <button 
                             className="overlay-email-btn" 
                             onClick={handleShare}
                             disabled={!validateEmail(shareEmail) || isEmailSending}
                           >
                             {isEmailSending ? 'Sending...' : 'Unlock Content'}
                           </button>
                    </div>
                  </div>
                </div>
              )}
              
                     {/* Content unlocked indicator for returning users */}
                     {hasValidEmail && showUnlockedNotification && (
                       <div className="content-unlocked-indicator">
                         <div className="unlocked-content">
                           <span className="unlock-icon">🔓</span>
                           <span className="unlock-text">Content unlocked for {localStorage.getItem('enable_user_email')}</span>
                         </div>
                       </div>
                     )}
            </div>

          </div>
        )}
      </div>
    </div>
  );
}

export default EventNetworkingAgent;
