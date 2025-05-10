from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
from app.services.weather_service import WeatherService
from app.services.auth_service import AuthService
from app.api.auth import oauth2_scheme

router = APIRouter()
weather_service = WeatherService()
auth_service = AuthService()

@router.get("/current")
async def get_current_weather(
    lat: float,
    lon: float,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """获取当前天气"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    weather_data = await weather_service.get_weather(lat, lon)
    if not weather_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Weather data not found"
        )
    return weather_data

@router.get("/forecast")
async def get_weather_forecast(
    lat: float,
    lon: float,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """获取天气预报"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    forecast_data = await weather_service.get_weather_forecast(lat, lon)
    if not forecast_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Forecast data not found"
        )
    return forecast_data

@router.get("/impact")
async def get_weather_impact(
    lat: float,
    lon: float,
    token: str = Depends(oauth2_scheme)
) -> Dict[str, Any]:
    """获取天气对电动车续航的影响"""
    user = auth_service.verify_token(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    weather_data = await weather_service.get_weather(lat, lon)
    if not weather_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Weather data not found"
        )
    
    impact = weather_service.calculate_weather_impact(weather_data)
    return {
        "weather_data": weather_data,
        "impact_factor": impact
    } 