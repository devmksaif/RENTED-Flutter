# Health Check API

## Overview

The Health Check endpoint allows you to verify that the API is running and accessible.

---

## Health Check Endpoints

### Check API Status

Get the current status of the API.

**Endpoint**: `GET /api/v1/`

**Authentication**: Not required

**Request Example**:

```bash
curl -X GET "http://localhost:8000/api/v1/" \
  -H "Accept: application/json"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "API is working",
  "version": "v1",
  "timestamp": "2025-12-03T14:30:45.000000Z"
}
```

**Response Fields**:

- `status` (string): Status indicator, typically "success"
- `message` (string): Human-readable status message
- `version` (string): API version (e.g., "v1")
- `timestamp` (string): Current server timestamp in ISO 8601 format

**Use Cases**:

- Verify API availability before making requests
- Monitor API health in automated systems
- Check API version compatibility
- Test network connectivity

**Notes**:

- This endpoint does not require authentication
- Response time is typically very fast (< 100ms)
- Useful for health checks and monitoring systems

---

## Error Responses

If the API is down or unreachable, you will receive a standard HTTP error response (e.g., 500, 503, or connection timeout).

---

## Example Usage

### Flutter Implementation

```dart
Future<bool> checkApiHealth() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/'),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    }
    return false;
  } catch (e) {
    return false;
  }
}
```

### JavaScript/TypeScript Implementation

```typescript
async function checkApiHealth(): Promise<boolean> {
  try {
    const response = await fetch('http://localhost:8000/api/v1/', {
      headers: { 'Accept': 'application/json' },
    });
    const data = await response.json();
    return data.status === 'success';
  } catch (error) {
    return false;
  }
}
```

---

## Best Practices

1. **Health Monitoring**: Use this endpoint for periodic health checks in production
2. **Error Handling**: Always handle connection timeouts gracefully
3. **Caching**: Don't cache health check responses for too long
4. **Rate Limiting**: Be mindful of rate limits when checking health frequently

