from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
from app.services.range_anxiety_service import RangeAnxietyService
from app.services.auth_service import AuthService
from app.api.auth import oauth2_scheme

router = APIRouter()
range_anxiety_service = RangeAnxietyService()
auth_service = AuthService()

@router.post("/calculate")
async def calculate_range_anxiety(
    vehicle_data: Dict[str, Any],
    weather_data: Dict[str, Any],
    route_data: Dict[str, Any],
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """计算续航焦虑指数"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    anxiety_data = range_anxiety_service.calculate_range_anxiety(
        vehicle_data,
        weather_data,
        route_data
    )
    
    if not anxiety_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to calculate range anxiety"
        )
    
    return anxiety_data

@router.get("/model-efficiency")
async def get_model_efficiency(
    model_type: str,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """获取特定车型的效率系数"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    efficiency = range_anxiety_service.model_efficiency.get(model_type)
    if not efficiency:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Model type not found"
        )
    
    return {
        "model_type": model_type,
        "efficiency_factor": efficiency
    } 