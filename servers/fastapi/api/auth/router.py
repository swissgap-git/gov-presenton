"""
EIAM Authentication Router for FastAPI
Provides OAuth2/OIDC endpoints for Swiss Federal EIAM integration
"""

from fastapi import APIRouter, HTTPException, status, Request, Depends
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional
import logging
import secrets

from .eiam_middleware import EIAMMiddleware, get_eiam_middleware, EIAMUser

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["authentication"])

class AuthResponse(BaseModel):
    """Authentication response model"""
    success: bool
    user: Optional[EIAMUser] = None
    token: Optional[str] = None
    error: Optional[str] = None

class LoginRequest(BaseModel):
    """Login request model"""
    redirect_url: Optional[str] = None

@router.get("/login")
async def login(
    request: Request,
    redirect_url: Optional[str] = None
):
    """
    Initiate EIAM OAuth2 login flow
    Redirects user to EIAM authorization endpoint
    """
    try:
        eiam = get_eiam_middleware()
        
        # Generate state parameter for CSRF protection
        state = secrets.token_urlsafe(32)
        
        # Store state and redirect_url in session
        request.session["auth_state"] = state
        if redirect_url:
            request.session["redirect_url"] = redirect_url
        
        # Get authorization URL
        auth_url = await eiam.get_authorization_url(state)
        
        return RedirectResponse(url=auth_url)
        
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to initiate login"
        )

@router.get("/callback")
async def auth_callback(
    request: Request,
    code: str,
    state: Optional[str] = None
):
    """
    Handle OAuth2 callback from EIAM
    Exchange authorization code for access token
    """
    try:
        # Verify state parameter
        stored_state = request.session.get("auth_state")
        if not stored_state or stored_state != state:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid state parameter"
            )
        
        # Clear state from session
        del request.session["auth_state"]
        
        # Exchange code for token
        eiam = get_eiam_middleware()
        token_data = await eiam.exchange_code_for_token(code)
        
        # Validate token and get user info
        access_token = token_data.get("access_token")
        user = await eiam.validate_token(access_token)
        
        # Store user and token in session
        request.session["user"] = user.dict()
        request.session["access_token"] = access_token
        
        # Redirect to original URL or default
        redirect_url = request.session.pop("redirect_url", "/")
        return RedirectResponse(url=redirect_url)
        
    except Exception as e:
        logger.error(f"Auth callback error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication failed"
        )

@router.get("/me", response_model=AuthResponse)
async def get_current_user_info(
    request: Request
):
    """
    Get current authenticated user information
    """
    try:
        user_data = request.session.get("user")
        if not user_data:
            return AuthResponse(success=False, error="Not authenticated")
        
        user = EIAMUser(**user_data)
        return AuthResponse(success=True, user=user)
        
    except Exception as e:
        logger.error(f"Get user info error: {str(e)}")
        return AuthResponse(success=False, error="Failed to get user info")

@router.post("/logout")
async def logout(request: Request):
    """
    Logout user and clear session
    """
    try:
        # Clear session
        request.session.clear()
        
        # Redirect to EIAM logout (optional)
        eiam = get_eiam_middleware()
        logout_url = f"{eiam.config.authority}/{eiam.config.tenant_id}/oauth2/v2.0/logout"
        
        return RedirectResponse(url=logout_url)
        
    except Exception as e:
        logger.error(f"Logout error: {str(e)}")
        # Even if logout fails, clear session
        request.session.clear()
        return {"success": True, "message": "Logged out"}

@router.get("/token", response_model=AuthResponse)
async def get_access_token(request: Request):
    """
    Get current access token
    """
    try:
        access_token = request.session.get("access_token")
        user_data = request.session.get("user")
        
        if not access_token or not user_data:
            return AuthResponse(success=False, error="Not authenticated")
        
        user = EIAMUser(**user_data)
        return AuthResponse(
            success=True,
            user=user,
            token=access_token
        )
        
    except Exception as e:
        logger.error(f"Get token error: {str(e)}")
        return AuthResponse(success=False, error="Failed to get token")

@router.get("/check")
async def check_authentication(
    request: Request
):
    """
    Check if user is authenticated
    """
    user_data = request.session.get("user")
    return {
        "authenticated": bool(user_data),
        "user": user_data if user_data else None
    }

# Middleware dependency for protected routes
async def get_authenticated_user(request: Request) -> EIAMUser:
    """Dependency for routes that require authentication"""
    user_data = request.session.get("user")
    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
    return EIAMUser(**user_data)
