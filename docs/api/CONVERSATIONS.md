# Conversations & Messages Endpoints

## Overview

This document covers all endpoints related to messaging and conversations between users in the Rented Marketplace API.

---

## Get User's Conversations

Retrieve all conversations for authenticated user.

**Endpoint**: `GET /conversations`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 1,
      "other_user": {
        "id": 2,
        "name": "Jane Doe",
        "avatar_url": "http://localhost:8000/storage/avatars/xyz789.jpg"
      },
      "product": {
        "id": 5,
        "title": "Professional Camera",
        "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg"
      },
      "last_message": {
        "content": "Is this still available?",
        "sender_id": 2,
        "created_at": "2025-12-05T10:30:00.000000Z"
      },
      "last_message_at": "2025-12-05T10:30:00.000000Z"
    }
  ]
}
```

**Notes**:
- Ordered by most recent message first
- Shows unread indicator if messages exist

---

## Get Conversation by ID

Get details of a specific conversation.

**Endpoint**: `GET /conversations/{id}`

**Authentication**: Required (Participant only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "other_user": {
      "id": 2,
      "name": "Jane Doe",
      "avatar_url": "http://localhost:8000/storage/avatars/xyz789.jpg"
    },
    "product": {
      "id": 5,
      "title": "Professional Camera",
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg"
    },
    "created_at": "2025-12-05T09:00:00.000000Z"
  }
}
```

**Errors**:

- **403 Forbidden**: Not a participant in conversation

---

## Get Conversation Messages

Retrieve all messages in a conversation.

**Endpoint**: `GET /conversations/{id}/messages`

**Authentication**: Required (Participant only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 1,
      "content": "Is this still available?",
      "sender": {
        "id": 2,
        "name": "Jane Doe"
      },
      "is_read": true,
      "read_at": "2025-12-05T10:35:00.000000Z",
      "created_at": "2025-12-05T10:30:00.000000Z"
    },
    {
      "id": 2,
      "content": "Yes, it's available!",
      "sender": {
        "id": 1,
        "name": "John Doe"
      },
      "is_read": false,
      "read_at": null,
      "created_at": "2025-12-05T10:32:00.000000Z"
    }
  ]
}
```

**Notes**:
- Messages ordered chronologically
- Automatically marks messages as read when retrieved

---

## Mark Conversation as Read

Mark all messages in a conversation as read.

**Endpoint**: `POST /conversations/{id}/read`

**Authentication**: Required (Participant only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "message": "Conversation marked as read"
}
```

---

## Get Unread Message Count

Get total count of unread messages for user.

**Endpoint**: `GET /conversations/unread/count`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "unread_count": 5
}
```

**Notes**:
- Useful for notification badges
- Count updates in real-time

---

## Send Message

Send a message in a conversation or start a new conversation.

**Endpoint**: `POST /messages`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body** (New Conversation):

```json
{
  "receiver_id": 2,
  "product_id": 5,
  "content": "Is this camera still available for rent?"
}
```

**Request Body** (Existing Conversation):

```json
{
  "conversation_id": 1,
  "content": "When can I pick it up?"
}
```

**Validation Rules**:

- `conversation_id`: required without receiver_id, must exist
- `receiver_id`: required without conversation_id, must exist, cannot be self
- `product_id`: required with receiver_id, must exist
- `content`: required, string, max 1000 characters

**Response** (201 Created):

```json
{
  "data": {
    "id": 3,
    "content": "When can I pick it up?",
    "sender": {
      "id": 1,
      "name": "John Doe"
    },
    "conversation_id": 1,
    "is_read": false,
    "created_at": "2025-12-05T11:00:00.000000Z"
  }
}
```

**Errors**:

- **422 Unprocessable Entity**: Validation failed
- **403 Forbidden**: Attempting to message self

**Notes**:
- Creates conversation automatically if doesn't exist
- Updates conversation's `last_message_at` timestamp

---
