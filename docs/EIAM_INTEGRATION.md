# EIAM Authentication Integration for Presenton

This guide explains how to configure Swiss Federal EIAM (Electronic Identity and Access Management) authentication for the Presenton application.

## Overview

The EIAM integration provides secure, enterprise-grade authentication using OAuth2/OIDC protocol, allowing federal employees to access Presenton with their existing credentials.

## Prerequisites

- EIAM application registration
- Client ID and Client Secret from EIAM
- Tenant ID for your organization
- HTTPS-enabled domain for callback handling

## Architecture

### Backend Components

1. **EIAM Middleware** (`servers/fastapi/api/auth/eiam_middleware.py`)
   - OAuth2/OIDC client implementation
   - JWT token validation
   - User information extraction

2. **Auth Router** (`servers/fastapi/api/auth/router.py`)
   - Login/logout endpoints
   - Callback handling
   - Session management

3. **Session Management**
   - Server-side session storage
   - Secure session cookies
   - Automatic token refresh

### Frontend Components

1. **Auth Context** (`servers/nextjs/contexts/AuthContext.tsx`)
   - Global authentication state
   - Login/logout functions
   - User session management

2. **Auth Components** (`servers/nextjs/components/auth/AuthComponents.tsx`)
   - Login/logout buttons
   - User menu with profile
   - Authentication guards

## Configuration

### 1. EIAM Application Setup

Register your application with EIAM:

1. Contact your EIAM administrator
2. Provide application details:
   - Name: "Presenton"
   - Redirect URI: `https://presenton.your-domain.ch/auth/callback`
   - Required permissions: User profile, email

### 2. Environment Variables

Configure the following environment variables:

#### Backend Configuration
```bash
# EIAM Configuration
EIAM_CLIENT_ID=your-eiam-client-id
EIAM_CLIENT_SECRET=your-eiam-client-secret
EIAM_TENANT_ID=your-eiam-tenant-id
EIAM_REDIRECT_URI=https://presenton.your-domain.ch/auth/callback

# Session Security
SESSION_SECRET_KEY=your-32-character-secret-key-minimum
```

#### Frontend Configuration
```bash
# API Endpoints
NEXT_PUBLIC_API_BASE_URL=https://presenton.your-domain.ch
NEXT_PUBLIC_AUTH_ENABLED=true
```

### 3. Kubernetes Deployment

Update your Kubernetes configuration:

#### Secrets (`k8s/secrets.yaml`)
```yaml
stringData:
  # EIAM Authentication
  session-secret-key: "your-session-secret-key-here-32-chars-minimum"
  eiam-client-id: "your-eiam-client-id-here"
  eiam-client-secret: "your-eiam-client-secret-here"
  eiam-tenant-id: "your-eiam-tenant-id-here"
```

#### ConfigMap (`k8s/configmap.yaml`)
```yaml
data:
  eiam-redirect-uri: "https://presenton.your-domain.ch/auth/callback"
  enable-eiam-auth: "true"
```

## Implementation Guide

### 1. Backend Integration

Add authentication to protected routes:

```python
from api.auth.router import get_authenticated_user

@app.get("/api/v1/protected-endpoint")
async def protected_endpoint(user: EIAMUser = Depends(get_authenticated_user)):
    return {"message": f"Hello {user.name}!"}
```

### 2. Frontend Integration

Wrap your application with AuthProvider:

```tsx
import { AuthProvider } from '@/contexts/AuthContext';

function App() {
  return (
    <AuthProvider>
      <YourApp />
    </AuthProvider>
  );
}
```

Use authentication components:

```tsx
import { LoginButton, UserMenu, AuthGuard } from '@/components/auth/AuthComponents';

function Header() {
  return <UserMenu />;
}

function ProtectedPage() {
  return (
    <AuthGuard>
      <YourProtectedContent />
    </AuthGuard>
  );
}
```

### 3. Role-Based Access

Implement role-based access control:

```tsx
<AuthGuard requireRole="presenton-admin">
  <AdminPanel />
</AuthGuard>
```

## Security Features

### Token Security
- JWT token validation with RS256
- Token expiration handling
- Automatic token refresh
- Secure token storage

### Session Security
- Server-side session management
- Secure, HTTP-only cookies
- CSRF protection with state parameters
- Session timeout configuration

### Network Security
- HTTPS-only communication
- CORS configuration
- Secure redirect handling
- Rate limiting support

## User Information

The EIAM integration provides the following user attributes:

```typescript
interface EIAMUser {
  sub: string;              // Unique identifier
  name?: string;            // Full name
  email?: string;           // Email address
  given_name?: string;      // First name
  family_name?: string;     // Last name
  roles: string[];         // User roles
  department?: string;     // Department
  organization?: string;  // Organization
}
```

## Testing

### Local Development
1. Configure local EIAM test environment
2. Update hosts file: `127.0.0.1 presenton.local`
3. Use test certificates for HTTPS

### Integration Testing
```bash
# Test authentication flow
curl -X GET "https://presenton.your-domain.ch/api/v1/auth/login"

# Check authentication status
curl -X GET "https://presenton.your-domain.ch/api/v1/auth/check" \
  -H "Cookie: session=your-session-cookie"
```

## Troubleshooting

### Common Issues

1. **Invalid Client Credentials**
   - Verify EIAM client ID and secret
   - Check tenant ID configuration

2. **Redirect URI Mismatch**
   - Ensure redirect URI matches EIAM registration
   - Use HTTPS in production

3. **Token Validation Errors**
   - Check clock synchronization
   - Verify JWKS endpoint accessibility

4. **Session Issues**
   - Clear browser cookies
   - Verify session secret key

### Debug Logging

Enable debug logging in FastAPI:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

Monitor authentication events:

```bash
kubectl logs deployment/presenton -f
```

## Best Practices

### Security
1. Use strong session secrets (32+ characters)
2. Enable HTTPS in production
3. Regularly rotate EIAM client secrets
4. Monitor authentication logs

### Performance
1. Cache JWKS keys for token validation
2. Implement session timeout policies
3. Use connection pooling for HTTP requests

### User Experience
1. Provide clear login/logout flows
2. Handle session expiration gracefully
3. Display user information prominently
4. Support role-based UI customization

## Migration

### From Basic Auth
1. Deploy with both auth systems enabled
2. Migrate user sessions gradually
3. Update client applications
4. Disable basic auth after migration

### Multiple Providers
The system supports multiple authentication providers:
- EIAM (primary)
- Basic auth (fallback)
- Guest access (optional)

Configure provider priority in environment variables.

## Support

For EIAM-specific issues:
- Contact your EIAM administrator
- Review EIAM documentation: https://docs.eiam.admin.ch
- Check federal authentication guidelines

For application issues:
- Review application logs
- Verify configuration settings
- Test with EIAM test environment
