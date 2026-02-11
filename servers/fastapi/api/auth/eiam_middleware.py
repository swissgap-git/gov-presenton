"""
EIAM Authentication Middleware for FastAPI
Supports OAuth2/OIDC integration with Swiss Federal EIAM system
"""

import os
import json
import logging
from typing import Optional, Dict, Any
from fastapi import HTTPException, status, Request
from fastapi.security import OAuth2AuthorizationCodeBearer
from jose import JWTError, jwt
from pydantic import BaseModel
import httpx

logger = logging.getLogger(__name__)

class EIAMConfig(BaseModel):
    """EIAM Configuration"""
    client_id: str
    client_secret: str
    authority: str = "https://login.microsoftonline.com"
    tenant_id: str
    scope: str = "openid profile email"
    redirect_uri: str

class EIAMUser(BaseModel):
    """EIAM User information"""
    sub: str  # Subject (unique identifier)
    name: Optional[str] = None
    email: Optional[str] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None
    roles: list = []
    department: Optional[str] = None
    organization: Optional[str] = None

class EIAMMiddleware:
    """EIAM Authentication Middleware"""
    
    def __init__(self, config: EIAMConfig):
        self.config = config
        self.oauth2_scheme = OAuth2AuthorizationCodeBearer(
            authorizationUrl=f"{config.authority}/{config.tenant_id}/oauth2/v2.0/authorize",
            tokenUrl=f"{config.authority}/{config.tenant_id}/oauth2/v2.0/token"
        )
        self.jwks_url = f"{config.authority}/{config.tenant_id}/discovery/v2.0/keys"
        self._jwks_cache = None
        
    async def get_jwks(self) -> Dict[str, Any]:
        """Get JSON Web Key Set for token validation"""
        if self._jwks_cache is None:
            async with httpx.AsyncClient() as client:
                response = await client.get(self.jwks_url)
                response.raise_for_status()
                self._jwks_cache = response.json()
        return self._jwks_cache
    
    async def validate_token(self, token: str) -> EIAMUser:
        """Validate JWT token and extract user information"""
        try:
            # Get token header to find key ID
            headers = jwt.get_unverified_header(token)
            key_id = headers.get('kid')
            
            if not key_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token missing key ID"
                )
            
            # Get matching key from JWKS
            jwks = await self.get_jwks()
            key = None
            for jwk in jwks.get('keys', []):
                if jwk.get('kid') == key_id:
                    key = jwk
                    break
            
            if not key:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Unable to find verification key"
                )
            
            # Decode and validate token
            payload = jwt.decode(
                token,
                key,
                algorithms=["RS256"],
                audience=self.config.client_id,
                issuer=f"{self.config.authority}/{self.config.tenant_id}/v2.0"
            )
            
            # Extract user information
            user = EIAMUser(
                sub=payload.get('sub'),
                name=payload.get('name'),
                email=payload.get('email') or payload.get('preferred_username'),
                given_name=payload.get('given_name'),
                family_name=payload.get('family_name'),
                roles=payload.get('roles', []),
                department=payload.get('department'),
                organization=payload.get('organization')
            )
            
            return user
            
        except JWTError as e:
            logger.error(f"JWT validation error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        except Exception as e:
            logger.error(f"Token validation error: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token validation failed"
            )
    
    async def get_authorization_url(self, state: str = None) -> str:
        """Generate authorization URL for OAuth2 flow"""
        params = {
            'client_id': self.config.client_id,
            'response_type': 'code',
            'redirect_uri': self.config.redirect_uri,
            'scope': self.config.scope,
            'response_mode': 'query'
        }
        
        if state:
            params['state'] = state
            
        param_string = '&'.join([f"{k}={v}" for k, v in params.items()])
        return f"{self.config.authority}/{self.config.tenant_id}/oauth2/v2.0/authorize?{param_string}"
    
    async def exchange_code_for_token(self, code: str) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        data = {
            'client_id': self.config.client_id,
            'client_secret': self.config.client_secret,
            'code': code,
            'redirect_uri': self.config.redirect_uri,
            'grant_type': 'authorization_code'
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.config.authority}/{self.config.tenant_id}/oauth2/v2.0/token",
                data=data
            )
            response.raise_for_status()
            return response.json()

# Global EIAM instance
_eiam_instance: Optional[EIAMMiddleware] = None

def get_eiam_config() -> EIAMConfig:
    """Get EIAM configuration from environment variables"""
    return EIAMConfig(
        client_id=os.getenv("EIAM_CLIENT_ID", ""),
        client_secret=os.getenv("EIAM_CLIENT_SECRET", ""),
        tenant_id=os.getenv("EIAM_TENANT_ID", ""),
        redirect_uri=os.getenv("EIAM_REDIRECT_URI", "http://localhost:3000/auth/callback")
    )

def get_eiam_middleware() -> EIAMMiddleware:
    """Get or create EIAM middleware instance"""
    global _eiam_instance
    if _eiam_instance is None:
        config = get_eiam_config()
        if not config.client_id or not config.client_secret or not config.tenant_id:
            raise ValueError("EIAM configuration missing. Please set EIAM_CLIENT_ID, EIAM_CLIENT_SECRET, and EIAM_TENANT_ID")
        _eiam_instance = EIAMMiddleware(config)
    return _eiam_instance

async def get_current_user(request: Request) -> Optional[EIAMUser]:
    """Get current authenticated user from request"""
    try:
        authorization = request.headers.get("Authorization")
        if not authorization or not authorization.startswith("Bearer "):
            return None
        
        token = authorization.split(" ")[1]
        eiam = get_eiam_middleware()
        return await eiam.validate_token(token)
    except Exception as e:
        logger.error(f"Error getting current user: {str(e)}")
        return None

async def require_auth(request: Request) -> EIAMUser:
    """Require authentication and return current user"""
    user = await get_current_user(request)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
    return user
