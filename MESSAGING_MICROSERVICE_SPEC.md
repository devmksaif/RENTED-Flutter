# Messaging Microservice Specification

## Overview

This document provides a detailed specification for building a messaging microservice that will handle all real-time communication features for the Rented Marketplace application. The microservice should be built as a separate, scalable service that integrates with the main Laravel API.

## Architecture Requirements

### Technology Stack Recommendations

**Option 1: Node.js + Socket.io (Recommended)**
- **Runtime**: Node.js 18+ with TypeScript
- **WebSocket**: Socket.io for real-time bidirectional communication
- **Database**: PostgreSQL 16 (same as main API) or MongoDB for message storage
- **Cache**: Redis 7 for session management and message queuing
- **Framework**: Express.js or Nest.js
- **Authentication**: JWT token validation (validate against main API)

**Option 2: Laravel + Laravel Reverb**
- **Framework**: Laravel 12
- **WebSocket**: Laravel Reverb (Pusher alternative)
- **Database**: PostgreSQL 16
- **Cache**: Redis 7
- **Authentication**: Laravel Sanctum token validation

**Option 3: Go + Gorilla WebSocket**
- **Language**: Go 1.21+
- **WebSocket**: Gorilla WebSocket
- **Database**: PostgreSQL 16
- **Cache**: Redis 7
- **Authentication**: JWT validation

### Recommended: Node.js + Socket.io + TypeScript

## Core Features

### 1. Real-Time Messaging
- WebSocket connections for instant message delivery
- Message typing indicators
- Online/offline status
- Message read receipts
- Message delivery status (sent, delivered, read)

### 2. Conversation Management
- Create conversations automatically when first message is sent
- List all conversations for a user
- Get conversation details
- Mark conversations as read
- Archive conversations
- Delete conversations

### 3. Message Features
- Send text messages
- Send images (via file upload or URL)
- Send file attachments
- Message timestamps
- Message editing (within time limit)
- Message deletion
- Message reactions (emoji)

### 4. Notifications
- Push notifications for new messages
- Email notifications (optional, configurable)
- In-app notification badges
- Unread message count

### 5. Advanced Features
- Message search within conversations
- Message pagination
- Message history sync
- Typing indicators
- User presence (online/offline)
- Last seen timestamp

## API Endpoints

### REST API Endpoints (HTTP)

#### Authentication
```
POST /auth/validate-token
Body: { "token": "bearer_token" }
Response: { "valid": true, "user_id": 123, "user": {...} }
```

#### Conversations
```
GET /api/conversations
Headers: Authorization: Bearer {token}
Response: {
  "data": [
    {
      "id": 1,
      "other_user": { "id": 2, "name": "Jane", "avatar_url": "..." },
      "product": { "id": 5, "title": "Camera", "thumbnail_url": "..." },
      "last_message": { "content": "...", "created_at": "..." },
      "unread_count": 3,
      "last_message_at": "2025-12-05T10:30:00Z"
    }
  ]
}

GET /api/conversations/:id
Response: {
  "data": {
    "id": 1,
    "other_user": {...},
    "product": {...},
    "created_at": "..."
  }
}

POST /api/conversations/:id/read
Mark all messages in conversation as read

DELETE /api/conversations/:id
Archive/delete conversation

GET /api/conversations/unread/count
Response: { "unread_count": 5 }
```

#### Messages
```
GET /api/conversations/:id/messages?page=1&limit=50
Response: {
  "data": [
    {
      "id": 1,
      "content": "Hello!",
      "sender": { "id": 1, "name": "John" },
      "conversation_id": 1,
      "is_read": false,
      "read_at": null,
      "created_at": "2025-12-05T10:30:00Z",
      "updated_at": "2025-12-05T10:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total": 250
  }
}

POST /api/messages
Body: {
  "conversation_id": 1,
  "content": "Hello!",
  "type": "text" // text, image, file
}
Response: { "data": {...message...} }

PUT /api/messages/:id
Body: { "content": "Updated message" }
Response: { "data": {...updated message...} }

DELETE /api/messages/:id
Response: 204 No Content
```

#### Search
```
GET /api/messages/search?query=hello&conversation_id=1
Response: {
  "data": [
    {
      "id": 123,
      "content": "Hello there!",
      "conversation_id": 1,
      "created_at": "..."
    }
  ]
}
```

## WebSocket Events

### Client → Server Events

#### Connection
```javascript
socket.emit('authenticate', { token: 'bearer_token' })
```

#### Join Conversation
```javascript
socket.emit('join_conversation', { conversation_id: 1 })
```

#### Send Message
```javascript
socket.emit('send_message', {
  conversation_id: 1,
  content: 'Hello!',
  type: 'text'
})
```

#### Typing Indicator
```javascript
socket.emit('typing', {
  conversation_id: 1,
  is_typing: true
})
```

#### Mark as Read
```javascript
socket.emit('mark_read', {
  conversation_id: 1,
  message_ids: [1, 2, 3]
})
```

#### User Presence
```javascript
socket.emit('presence_update', {
  status: 'online' // online, away, offline
})
```

### Server → Client Events

#### Message Received
```javascript
socket.on('message_received', (data) => {
  // data: { message: {...}, conversation_id: 1 }
})
```

#### Message Sent (Confirmation)
```javascript
socket.on('message_sent', (data) => {
  // data: { message: {...}, message_id: 123 }
})
```

#### Typing Indicator
```javascript
socket.on('user_typing', (data) => {
  // data: { user_id: 2, conversation_id: 1, is_typing: true }
})
```

#### Message Read
```javascript
socket.on('message_read', (data) => {
  // data: { message_ids: [1, 2, 3], user_id: 2, conversation_id: 1 }
})
```

#### User Presence
```javascript
socket.on('user_presence', (data) => {
  // data: { user_id: 2, status: 'online', last_seen: '...' }
})
```

#### Conversation Updated
```javascript
socket.on('conversation_updated', (data) => {
  // data: { conversation: {...} }
})
```

#### Error
```javascript
socket.on('error', (data) => {
  // data: { message: 'Error message', code: 'ERROR_CODE' }
})
```

## Database Schema

### conversations
```sql
CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  user1_id INTEGER NOT NULL,
  user2_id INTEGER NOT NULL,
  product_id INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_message_at TIMESTAMP,
  UNIQUE(user1_id, user2_id, product_id)
);

CREATE INDEX idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX idx_conversations_user2 ON conversations(user2_id);
CREATE INDEX idx_conversations_product ON conversations(product_id);
```

### messages
```sql
CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  type VARCHAR(20) DEFAULT 'text', -- text, image, file
  file_url VARCHAR(500),
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
```

### conversation_participants
```sql
CREATE TABLE conversation_participants (
  id SERIAL PRIMARY KEY,
  conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL,
  unread_count INTEGER DEFAULT 0,
  last_read_at TIMESTAMP,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_participants_user ON conversation_participants(user_id);
```

### message_reactions
```sql
CREATE TABLE message_reactions (
  id SERIAL PRIMARY KEY,
  message_id INTEGER NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL,
  emoji VARCHAR(10) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);
```

## Integration with Main API

### Authentication Flow

1. **Token Validation**
   - Microservice should validate JWT tokens with main API
   - Endpoint: `GET /api/v1/user` (main API)
   - Cache validated tokens in Redis (TTL: 1 hour)

2. **User Data Sync**
   - Fetch user data from main API when needed
   - Cache user data in Redis
   - Endpoint: `GET /api/v1/user` (main API)

3. **Product Data**
   - Fetch product data from main API
   - Cache product data in Redis
   - Endpoint: `GET /api/v1/products/:id` (main API)

### API Communication

```javascript
// Example: Validate token with main API
async function validateToken(token) {
  const response = await fetch('http://main-api:8000/api/v1/user', {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json'
    }
  });
  
  if (response.ok) {
    const data = await response.json();
    return { valid: true, user: data.data };
  }
  return { valid: false };
}
```

## Real-Time Implementation

### Socket.io Server Setup

```typescript
import { Server } from 'socket.io';
import { createServer } from 'http';

const httpServer = createServer();
const io = new Server(httpServer, {
  cors: {
    origin: "*", // Configure properly for production
    methods: ["GET", "POST"]
  }
});

// Authentication middleware
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  const validation = await validateToken(token);
  
  if (validation.valid) {
    socket.data.user = validation.user;
    next();
  } else {
    next(new Error('Authentication failed'));
  }
});

io.on('connection', (socket) => {
  const userId = socket.data.user.id;
  
  // Join user's personal room
  socket.join(`user:${userId}`);
  
  // Handle joining conversation
  socket.on('join_conversation', async ({ conversation_id }) => {
    // Verify user is part of conversation
    const isParticipant = await verifyParticipant(userId, conversation_id);
    if (isParticipant) {
      socket.join(`conversation:${conversation_id}`);
    }
  });
  
  // Handle sending messages
  socket.on('send_message', async (data) => {
    const message = await saveMessage(data);
    
    // Emit to all participants in conversation
    io.to(`conversation:${data.conversation_id}`)
      .emit('message_received', { message });
    
    // Emit confirmation to sender
    socket.emit('message_sent', { message });
  });
  
  // Handle typing indicators
  socket.on('typing', ({ conversation_id, is_typing }) => {
    socket.to(`conversation:${conversation_id}`)
      .emit('user_typing', {
        user_id: userId,
        conversation_id,
        is_typing
      });
  });
  
  // Handle disconnect
  socket.on('disconnect', () => {
    // Update user presence
    updateUserPresence(userId, 'offline');
  });
});
```

## Environment Variables

```env
# Server
PORT=3001
NODE_ENV=production

# Main API
MAIN_API_URL=http://167.86.87.72:8000/api/v1
MAIN_API_TIMEOUT=5000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/messaging_db
DB_POOL_MIN=2
DB_POOL_MAX=10

# Redis
REDIS_URL=redis://localhost:6379
REDIS_TTL=3600

# JWT
JWT_SECRET=your_jwt_secret
JWT_ISSUER=rented-marketplace

# CORS
CORS_ORIGIN=http://localhost:3000,https://yourdomain.com

# File Upload (if handling file uploads)
MAX_FILE_SIZE=10485760
UPLOAD_DIR=./uploads
```

## Deployment

### Docker Configuration

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3001

CMD ["node", "dist/index.js"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  messaging-service:
    build: .
    ports:
      - "3001:3001"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/messaging
      - REDIS_URL=redis://redis:6379
      - MAIN_API_URL=http://main-api:8000/api/v1
    depends_on:
      - postgres
      - redis
    networks:
      - rented-network

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: messaging
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - messaging_db:/var/lib/postgresql/data
    networks:
      - rented-network

  redis:
    image: redis:7-alpine
    networks:
      - rented-network

networks:
  rented-network:
    external: true

volumes:
  messaging_db:
```

## Testing Requirements

### Unit Tests
- Message creation logic
- Conversation management
- Authentication validation
- Database operations

### Integration Tests
- WebSocket connection flow
- Message delivery
- Real-time event handling
- API endpoint responses

### Load Tests
- Handle 1000+ concurrent connections
- Message throughput: 1000 messages/second
- Low latency: < 100ms message delivery

## Security Considerations

1. **Authentication**: Always validate tokens with main API
2. **Authorization**: Verify user is participant before allowing access
3. **Rate Limiting**: Implement rate limits on message sending
4. **Input Validation**: Sanitize all message content
5. **CORS**: Configure properly for production
6. **HTTPS/WSS**: Use secure connections in production
7. **SQL Injection**: Use parameterized queries
8. **XSS Prevention**: Sanitize user input

## Performance Optimization

1. **Redis Caching**: Cache user data, product data, conversations
2. **Message Pagination**: Load messages in chunks (50 per page)
3. **Connection Pooling**: Use database connection pooling
4. **Message Queuing**: Use Redis for message queuing if needed
5. **Horizontal Scaling**: Support multiple server instances with Redis pub/sub

## Monitoring & Logging

1. **Logging**: Use structured logging (Winston, Pino)
2. **Metrics**: Track message count, active connections, latency
3. **Error Tracking**: Integrate with Sentry or similar
4. **Health Checks**: `/health` endpoint for monitoring

## API Response Format

All responses should follow this format:

```json
{
  "success": true,
  "data": {...},
  "meta": {
    "timestamp": "2025-12-05T10:30:00Z"
  }
}
```

Error responses:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {...}
  }
}
```

## Implementation Checklist

- [ ] Set up project structure
- [ ] Configure database schema
- [ ] Implement authentication middleware
- [ ] Create REST API endpoints
- [ ] Implement WebSocket server
- [ ] Add real-time message delivery
- [ ] Implement typing indicators
- [ ] Add read receipts
- [ ] Implement user presence
- [ ] Add message search
- [ ] Implement pagination
- [ ] Add caching layer
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Set up Docker configuration
- [ ] Configure environment variables
- [ ] Add logging and monitoring
- [ ] Performance testing
- [ ] Security audit
- [ ] Documentation

## Frontend Integration

The Flutter app will connect to this microservice using:
- **REST API**: For fetching conversations and messages
- **WebSocket**: For real-time message delivery and updates

The frontend service layer is already prepared in:
- `lib/services/conversation_service.dart`
- `lib/services/message_service.dart`

These services will need to be updated to point to the microservice URL instead of the main API.

## Next Steps

1. Choose technology stack (recommended: Node.js + Socket.io)
2. Set up project structure
3. Implement database schema
4. Build REST API endpoints
5. Implement WebSocket server
6. Add real-time features
7. Integrate with main API for authentication
8. Deploy and test
9. Update Flutter app to use microservice endpoints

