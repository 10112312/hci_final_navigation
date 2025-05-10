import os
import aiohttp
import logging
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

logger = logging.getLogger(__name__)

class TeslaService:
    def __init__(self):
        self.client_id = os.getenv("TESLA_CLIENT_ID")
        self.client_secret = os.getenv("TESLA_CLIENT_SECRET")
        
        if not self.client_id or not self.client_secret:
            logger.error("TESLA_CLIENT_ID or TESLA_CLIENT_SECRET not found in environment variables")
            raise ValueError("Tesla API credentials are required")
            
        self.base_url = "https://owner-api.teslamotors.com/api/1"
        self.auth_url = "https://auth.tesla.com/oauth2/v3"
        self.token = None

    async def get_access_token(self, email: str, password: str) -> Optional[str]:
        """获取访问令牌"""
        try:
            async with aiohttp.ClientSession() as session:
                # 第一步：获取授权码
                auth_data = {
                    "grant_type": "password",
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "email": email,
                    "password": password
                }
                
                async with session.post(
                    f"{self.auth_url}/token",
                    json=auth_data
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        self.token = data.get("access_token")
                        return self.token
                    logger.error(f"Failed to get access token: {response.status}")
                    return None
        except Exception as e:
            logger.error(f"Error getting access token: {str(e)}")
            return None

    async def get_vehicles(self) -> List[Dict[str, Any]]:
        """获取用户的所有车辆"""
        if not self.token:
            logger.error("No access token available")
            return []
            
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.base_url}/vehicles",
                    headers={"Authorization": f"Bearer {self.token}"}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get("response", [])
                    logger.error(f"Failed to get vehicles: {response.status}")
                    return []
        except Exception as e:
            logger.error(f"Error getting vehicles: {str(e)}")
            return []

    async def get_supercharger_locations(self) -> List[Dict[str, Any]]:
        """获取所有Tesla超级充电站位置"""
        if not self.token:
            logger.error("No access token available")
            return []
            
        try:
            url = f"{self.base_url}/superchargers"
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    url,
                    headers={"Authorization": f"Bearer {self.token}"}
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get("response", [])
                    logger.error(f"Failed to get superchargers: {response.status}")
                    return []
        except Exception as e:
            logger.error(f"Error getting superchargers: {str(e)}")
            return []

    async def get_vehicle_data(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        """获取特定车辆的数据"""
        if not self.token:
            logger.error("No access token available")
            return None
            
        try:
            url = f"{self.base_url}/vehicles/{vehicle_id}/vehicle_data"
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    url,
                    headers={"Authorization": f"Bearer {self.token}"}
                ) as response:
                    if response.status == 200:
                        return await response.json()
                    logger.error(f"Failed to get vehicle data: {response.status}")
                    return None
        except Exception as e:
            logger.error(f"Error getting vehicle data: {str(e)}")
            return None

    async def get_vehicle_state(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        """获取车辆状态"""
        if not self.token:
            logger.error("No access token available")
            return None
            
        try:
            url = f"{self.base_url}/vehicles/{vehicle_id}/vehicle_state"
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    url,
                    headers={"Authorization": f"Bearer {self.token}"}
                ) as response:
                    if response.status == 200:
                        return await response.json()
                    logger.error(f"Failed to get vehicle state: {response.status}")
                    return None
        except Exception as e:
            logger.error(f"Error getting vehicle state: {str(e)}")
            return None

    async def wake_up_vehicle(self, vehicle_id: str) -> bool:
        """唤醒车辆"""
        if not self.token:
            logger.error("No access token available")
            return False
            
        try:
            url = f"{self.base_url}/vehicles/{vehicle_id}/wake_up"
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    url,
                    headers={"Authorization": f"Bearer {self.token}"}
                ) as response:
                    return response.status == 200
        except Exception as e:
            logger.error(f"Error waking up vehicle: {str(e)}")
            return False

    def calculate_route_with_charging(
        self,
        start_location: Dict[str, float],
        end_location: Dict[str, float],
        current_battery_level: float,
        max_range: float,
        superchargers: List[Dict[str, Any]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        计算包含充电站的路线
        """
        try:
            if not superchargers:
                logger.error("No supercharger data available")
                return None

            # 计算直接距离
            direct_distance = self._calculate_distance(
                start_location["lat"],
                start_location["lon"],
                end_location["lat"],
                end_location["lon"]
            )

            # 检查是否需要充电
            estimated_consumption = (direct_distance / max_range) * 100
            if current_battery_level >= estimated_consumption:
                return {
                    "route": [start_location, end_location],
                    "charging_stops": [],
                    "total_distance": direct_distance,
                    "estimated_consumption": estimated_consumption
                }

            # 寻找最佳充电站
            best_route = self._find_best_route(
                start_location,
                end_location,
                current_battery_level,
                max_range,
                superchargers
            )

            if not best_route:
                logger.error("Could not find a valid route with charging stations")
                return None

            return best_route

        except Exception as e:
            logger.error(f"Error calculating route: {str(e)}")
            return None

    def _calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """计算两点之间的距离（公里）"""
        from math import radians, sin, cos, sqrt, atan2
        
        R = 6371  # 地球半径（公里）

        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        distance = R * c

        return distance

    def _find_best_route(
        self,
        start: Dict[str, float],
        end: Dict[str, float],
        current_battery: float,
        max_range: float,
        superchargers: List[Dict[str, Any]]
    ) -> Optional[Dict[str, Any]]:
        """寻找最佳路线"""
        try:
            # 按距离排序充电站
            sorted_chargers = sorted(
                superchargers,
                key=lambda x: self._calculate_distance(
                    start["lat"],
                    start["lon"],
                    x["location"]["lat"],
                    x["location"]["lon"]
                )
            )

            route = [start]
            charging_stops = []
            total_distance = 0
            remaining_battery = current_battery

            current_pos = start
            while True:
                # 检查是否能直接到达终点
                direct_distance = self._calculate_distance(
                    current_pos["lat"],
                    current_pos["lon"],
                    end["lat"],
                    end["lon"]
                )
                estimated_consumption = (direct_distance / max_range) * 100

                if remaining_battery >= estimated_consumption:
                    route.append(end)
                    total_distance += direct_distance
                    break

                # 寻找最近的充电站
                next_charger = None
                for charger in sorted_chargers:
                    charger_distance = self._calculate_distance(
                        current_pos["lat"],
                        current_pos["lon"],
                        charger["location"]["lat"],
                        charger["location"]["lon"]
                    )
                    charger_consumption = (charger_distance / max_range) * 100

                    if remaining_battery >= charger_consumption:
                        next_charger = charger
                        break

                if not next_charger:
                    logger.error("No reachable charging station found")
                    return None

                # 添加到路线
                route.append(next_charger["location"])
                charging_stops.append(next_charger)
                total_distance += self._calculate_distance(
                    current_pos["lat"],
                    current_pos["lon"],
                    next_charger["location"]["lat"],
                    next_charger["location"]["lon"]
                )
                remaining_battery = 100  # 假设在充电站充满电
                current_pos = next_charger["location"]

            return {
                "route": route,
                "charging_stops": charging_stops,
                "total_distance": total_distance,
                "estimated_consumption": (total_distance / max_range) * 100
            }

        except Exception as e:
            logger.error(f"Error finding best route: {str(e)}")
            return None 