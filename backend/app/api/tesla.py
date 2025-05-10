from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from typing import Dict, Any, List
from ..services.tesla_service import TeslaService
from ..core.logging import logger

router = APIRouter()
tesla_service = TeslaService()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@router.post("/login")
async def login(email: str, password: str):
    """登录 Tesla 账号"""
    try:
        token = await tesla_service.get_access_token(email, password)
        if not token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        return {"access_token": token, "token_type": "bearer"}
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to authenticate with Tesla"
        )

@router.get("/vehicles", response_model=List[Dict[str, Any]])
async def get_vehicles(token: str = Depends(oauth2_scheme)):
    """获取用户的所有车辆"""
    try:
        tesla_service.token = token
        vehicles = await tesla_service.get_vehicles()
        if not vehicles:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No vehicles found"
            )
        return vehicles
    except Exception as e:
        logger.error(f"Error getting vehicles: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get vehicles"
        )

@router.get("/superchargers", response_model=List[Dict[str, Any]])
async def get_superchargers(token: str = Depends(oauth2_scheme)):
    """获取所有超级充电站位置"""
    try:
        tesla_service.token = token
        superchargers = await tesla_service.get_supercharger_locations()
        if not superchargers:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No superchargers found"
            )
        return superchargers
    except Exception as e:
        logger.error(f"Error getting superchargers: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get superchargers"
        )

@router.get("/vehicles/{vehicle_id}", response_model=Dict[str, Any])
async def get_vehicle_data(vehicle_id: str, token: str = Depends(oauth2_scheme)):
    """获取特定车辆的数据"""
    try:
        tesla_service.token = token
        vehicle_data = await tesla_service.get_vehicle_data(vehicle_id)
        if not vehicle_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )
        return vehicle_data
    except Exception as e:
        logger.error(f"Error getting vehicle data: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get vehicle data"
        )

@router.get("/vehicles/{vehicle_id}/state", response_model=Dict[str, Any])
async def get_vehicle_state(vehicle_id: str, token: str = Depends(oauth2_scheme)):
    """获取车辆状态"""
    try:
        tesla_service.token = token
        state = await tesla_service.get_vehicle_state(vehicle_id)
        if not state:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle state not found"
            )
        return state
    except Exception as e:
        logger.error(f"Error getting vehicle state: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get vehicle state"
        )

@router.post("/vehicles/{vehicle_id}/wake")
async def wake_up_vehicle(vehicle_id: str, token: str = Depends(oauth2_scheme)):
    """唤醒车辆"""
    try:
        tesla_service.token = token
        success = await tesla_service.wake_up_vehicle(vehicle_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to wake up vehicle"
            )
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error waking up vehicle: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to wake up vehicle"
        )

@router.post("/route")
async def calculate_route(
    start_location: Dict[str, float],
    end_location: Dict[str, float],
    current_battery_level: float,
    max_range: float,
    token: str = Depends(oauth2_scheme)
):
    """计算包含充电站的路线"""
    try:
        tesla_service.token = token
        superchargers = await tesla_service.get_supercharger_locations()
        route = tesla_service.calculate_route_with_charging(
            start_location,
            end_location,
            current_battery_level,
            max_range,
            superchargers
        )
        if not route:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not calculate route"
            )
        return route
    except Exception as e:
        logger.error(f"Error calculating route: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to calculate route"
        ) 